import 'dart:convert';

import 'package:etrip/core/mock_data.dart';
import 'package:etrip/features/auth/data/egyptopia_api_service.dart';
import 'package:etrip/features/auth/data/services/local_storage_service.dart';
import 'package:etrip/features/chat_bot/data/backend_chat_completer.dart';
import 'package:etrip/features/chat_bot/domain/chat_completer.dart';
import 'package:etrip/features/weather/data/weather_api.dart';
import 'package:etrip/features/wishlist/data/service/favorite_service.dart';

/// 查天气的入口（可注入，便于测试里换掉真实网络调用）。
typedef WeatherLookup = Future<Map<String, dynamic>> Function(
  String city, {
  String lang,
});

/// 聊天机器人的业务层：拼系统提示词 → 调模型 → 需要时执行工具 → 再调一轮。
///
/// 这里只做「循环」，一次补全交给 [ChatCompleter]：
/// - 生产环境是 [BackendChatCompleter]，走自建后端的 `POST /api/chat`，
///   **DeepSeek 密钥留在服务端**，客户端不再持有；
/// - 测试里换成假的，就能确定性地验证工具循环。
///
/// 工具（查天气）仍然在客户端执行 —— 天气 API 的密钥不必再往服务端搬一份，
/// 后端只当透传。因此循环也只能留在客户端，每轮补全都是独立的一次请求。
class ChatApiService {
  /// 最多两轮工具调用，之后强制要求直接回答。
  static const int _maxToolRounds = 2;

  final ChatCompleter _completer;
  final WeatherLookup _weatherLookup;

  ChatApiService({
    ChatCompleter? completer,
    WeatherLookup? weatherLookup,
  })  : _completer = completer ?? BackendChatCompleter(),
        _weatherLookup = weatherLookup ??
            ((city, {String lang = 'en'}) =>
                WeatherApi().getWeatherByCity(city, lang: lang));

  static const List<Map<String, dynamic>> _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'get_weather',
        'description':
            'Get the current real-time weather of a city in China. ONLY call this when the user explicitly asks about the weather. Never bring up weather on your own.',
        'parameters': {
          'type': 'object',
          'properties': {
            'city': {
              'type': 'string',
              'description':
                  'City name in English, e.g. Beijing, Shanghai, Chengdu',
            },
          },
          'required': ['city'],
        },
      },
    },
  ];

  /// [history] uses the chat page format: {'role': 'user'|'bot', 'text': ...}.
  Future<String> chat(List<Map<String, String>> history, String lang) async {
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': await _buildSystemPrompt(lang)},
      for (final m in history)
        {
          'role': m['role'] == 'user' ? 'user' : 'assistant',
          'content': m['text'] ?? '',
        },
    ];

    for (var round = 0; ; round++) {
      // 前两轮带上工具定义；再往后就不带了，逼模型直接把话说出来。
      final completion = await _completer.complete(
        messages: messages,
        tools: round < _maxToolRounds ? _tools : null,
      );

      if (!completion.wantsTools) {
        return completion.content;
      }

      // 已经是不带工具的那一轮，模型还在要求调工具 —— 不再无谓地循环下去。
      if (round >= _maxToolRounds) {
        throw const ChatException('模型连续要求调用工具，已放弃这一轮');
      }

      // 助手这条（含 tool_calls）必须原样入史，接着把每个工具结果按 id 接上去，
      // 否则下一轮上游会因为「tool_call 没有对应的结果」直接报错。
      messages.add(completion.message);
      for (final call in completion.toolCalls) {
        messages.add({
          'role': 'tool',
          'tool_call_id': call['id'],
          'content': await _executeTool(call, lang),
        });
      }
    }
  }

  Future<String> _executeTool(Map<String, dynamic> call, String lang) async {
    final function = call['function'] ?? {};
    if (function['name'] != 'get_weather') {
      return jsonEncode({'error': 'unknown tool'});
    }
    try {
      final args = jsonDecode(function['arguments'] ?? '{}');
      final city = (args['city'] ?? '').toString();
      final weather = await _weatherLookup(
        city,
        lang: lang == 'zh' ? 'zh_cn' : 'en',
      );
      if (weather.containsKey('error')) {
        return jsonEncode({'error': weather['error']});
      }
      return jsonEncode({
        'city': weather['city'],
        'temperature_c': weather['temperature'],
        'feels_like_c': weather['feelsLike'],
        'description': weather['description'],
        'humidity_percent': weather['humidity'],
        'wind_speed_ms': weather['windSpeed'],
      });
    } catch (e) {
      return jsonEncode({'error': 'failed to fetch weather'});
    }
  }

  Future<String> _buildSystemPrompt(String lang) async {
    final isZh = lang == 'zh';
    final buffer = StringBuffer();

    buffer.writeln(isZh
        ? '你是 Etrip 旅行 App 的智能旅行助手，专注中国旅游。请始终用中文回答，语气友好，回答简洁（不超过200字），多用具体建议。'
        : 'You are the AI travel assistant of the Etrip travel app, specialized in travel in China. Always answer in English, in a friendly tone, concisely (under 150 words), with concrete suggestions.');

    final placeList = mockPlaces.map((p) {
      final name = isZh ? (placeNamesZh[p.id] ?? p.name) : p.name;
      final city = isZh ? (cityNamesZh[p.cityName] ?? p.cityName) : p.cityName;
      return '$name($city)';
    }).join(', ');
    buffer.writeln(isZh
        ? '本 App 收录的景点有：$placeList。推荐景点时请优先推荐这些。'
        : 'Places featured in this app: $placeList. Prefer recommending these when suggesting places.');

    final favorites = _favoritesLine(isZh);
    if (favorites != null) buffer.writeln(favorites);

    final preferences = await _preferencesLine(isZh);
    if (preferences != null) buffer.writeln(preferences);

    return buffer.toString();
  }

  String? _favoritesLine(bool isZh) {
    try {
      final favorites = FavoriteService.getAllFavorites();
      if (favorites.isEmpty) return null;
      final items = favorites.map((f) {
        final name = isZh ? (placeNamesZh[f.id] ?? f.title) : f.title;
        final city = isZh ? (cityNamesZh[f.city] ?? f.city) : f.city;
        return '$name($city)';
      }).join(', ');
      return isZh
          ? '用户在 App 中收藏了：$items。当用户要求个性化推荐时，请参考这些收藏。'
          : 'The user has favorited in the app: $items. Use these when asked for personalized recommendations.';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _preferencesLine(bool isZh) async {
    try {
      final uid = LocalStorageService().currentUid;
      if (uid == null || uid.isEmpty) return null;
      final prefs = await EgyptopiaApiService()
          .getUserPreferences(uid)
          .timeout(const Duration(seconds: 2));
      if (prefs == null) return null;
      final categories = List<String>.from(prefs['category'] ?? []);
      final cities = List<String>.from(prefs['city'] ?? []);
      if (categories.isEmpty && cities.isEmpty) return null;
      return isZh
          ? '用户的旅行偏好：类型 ${categories.join('、')}；城市 ${cities.join('、')}。'
          : 'User travel preferences: categories ${categories.join(', ')}; cities ${cities.join(', ')}.';
    } catch (_) {
      return null;
    }
  }
}
