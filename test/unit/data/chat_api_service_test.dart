import 'dart:convert';

import 'package:etrip/features/chat_bot/data/chat_api_service.dart';
import 'package:etrip/features/chat_bot/domain/chat_completer.dart';
import 'package:flutter_test/flutter_test.dart';

/// 假的补全器：按顺序吐出预先排好的响应，并把每次收到的 messages 记下来。
class _FakeCompleter implements ChatCompleter {
  _FakeCompleter(this._responses);

  final List<ChatCompletion> _responses;
  final List<List<Map<String, dynamic>>> sentMessages = [];
  final List<List<Map<String, dynamic>>?> sentTools = [];
  int _index = 0;

  @override
  Future<ChatCompletion> complete({
    required List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
  }) async {
    sentMessages.add(
      [for (final m in messages) Map<String, dynamic>.from(m)],
    );
    sentTools.add(tools);
    if (_index >= _responses.length) {
      throw StateError('假的补全器只准备了 ${_responses.length} 条响应');
    }
    return _responses[_index++];
  }
}

ChatCompletion _plain(String text) => ChatCompletion(
      message: {'role': 'assistant', 'content': text},
    );

ChatCompletion _wantsWeather(
  String city, {
  String id = 'call_weather_1',
  String name = 'get_weather',
}) =>
    ChatCompletion(
      message: {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {
            'id': id,
            'type': 'function',
            'function': {'name': name, 'arguments': jsonEncode({'city': city})},
          }
        ],
      },
      finishReason: 'tool_calls',
    );

void main() {
  final history = [
    {'role': 'user', 'text': '成都有什么好玩的？'},
  ];

  test('不需要工具时一次补全就结束，且第一轮带上了工具定义', () async {
    final completer = _FakeCompleter([_plain('宽窄巷子和熊猫基地。')]);
    final api = ChatApiService(
      completer: completer,
      weatherLookup: (city, {lang = 'en'}) async => fail('不该查天气'),
    );

    final reply = await api.chat(history, 'zh');

    expect(reply, '宽窄巷子和熊猫基地。');
    expect(completer.sentMessages, hasLength(1));
    expect(completer.sentTools.single, isNotNull);

    // 第一条必须是本地拼出来的 system 提示词（收藏/偏好拿不到时只是少几行，不影响）。
    final system = completer.sentMessages.single.first;
    expect(system['role'], 'system');
    expect(system['content'], contains('Etrip'));

    // 历史里页面的 'user'/'bot' 要映射成上游认识的 'user'/'assistant'。
    expect(completer.sentMessages.single[1]['role'], 'user');
    expect(completer.sentMessages.single[1]['content'], '成都有什么好玩的？');
  });

  test('模型要工具 → 执行后把结果按 tool_call_id 接回去，再问一轮', () async {
    final completer = _FakeCompleter([
      _wantsWeather('Chengdu'),
      _plain('成都今天 22 度，多云。'),
    ]);
    final queried = <String>[];
    final api = ChatApiService(
      completer: completer,
      weatherLookup: (city, {lang = 'en'}) async {
        queried.add('$city/$lang');
        return {
          'city': 'Chengdu',
          'temperature': 22,
          'feelsLike': 21,
          'description': '多云',
          'humidity': 60,
          'windSpeed': 2.5,
        };
      },
    );

    final reply = await api.chat(history, 'en');

    expect(reply, '成都今天 22 度，多云。');
    expect(queried, ['Chengdu/en']);
    expect(completer.sentMessages, hasLength(2));

    // 第二轮的消息序列：… user, assistant(tool_calls), tool(结果)
    final second = completer.sentMessages[1];
    final assistant = second[second.length - 2];
    final toolMessage = second.last;

    expect(assistant['role'], 'assistant');
    expect(assistant['tool_calls'][0]['id'], 'call_weather_1');

    expect(toolMessage['role'], 'tool');
    expect(toolMessage['tool_call_id'], 'call_weather_1');

    final payload = jsonDecode(toolMessage['content'] as String) as Map;
    expect(payload['temperature_c'], 22);
    expect(payload['description'], '多云');
  });

  test('中文界面把 lang 转成 zh_cn 传给天气接口', () async {
    final completer = _FakeCompleter([_wantsWeather('成都'), _plain('好')]);
    final queried = <String>[];
    final api = ChatApiService(
      completer: completer,
      weatherLookup: (city, {lang = 'en'}) async {
        queried.add(lang);
        return {'temperature': 1};
      },
    );

    await api.chat(history, 'zh');
    expect(queried, ['zh_cn']);
  });

  test('第三轮（工具轮数用尽）不再带工具定义', () async {
    final completer = _FakeCompleter([
      _wantsWeather('A'),
      _wantsWeather('B', id: 'call_2'),
      _plain('直接回答'),
    ]);
    final api = ChatApiService(
      completer: completer,
      weatherLookup: (city, {lang = 'en'}) async => {'temperature': 10},
    );

    final reply = await api.chat(history, 'en');

    expect(reply, '直接回答');
    expect(completer.sentTools, hasLength(3));
    expect(completer.sentTools[0], isNotNull);
    expect(completer.sentTools[1], isNotNull);
    expect(completer.sentTools[2], isNull, reason: '最后一轮逼模型直接说话');
  });

  test('不带工具了还在要工具 → 抛 ChatException，不会无限循环', () async {
    final completer = _FakeCompleter([
      _wantsWeather('A'),
      _wantsWeather('B', id: 'call_2'),
      _wantsWeather('C', id: 'call_3'),
    ]);
    final api = ChatApiService(
      completer: completer,
      weatherLookup: (city, {lang = 'en'}) async => {'temperature': 10},
    );

    await expectLater(
      api.chat(history, 'en'),
      throwsA(isA<ChatException>()),
    );
    expect(completer.sentMessages, hasLength(3), reason: '最多问三轮');
  });

  test('天气查不到 → 把错误照实告诉模型，仍然能拿到回答', () async {
    final completer = _FakeCompleter([_wantsWeather('Nowhere'), _plain('查不到。')]);
    final api = ChatApiService(
      completer: completer,
      weatherLookup: (city, {lang = 'en'}) async => {'error': 'city not found'},
    );

    final reply = await api.chat(history, 'en');

    expect(reply, '查不到。');
    final toolMessage = completer.sentMessages[1].last;
    expect(jsonDecode(toolMessage['content'] as String), {'error': 'city not found'});
  });

  test('天气接口抛异常 → 兜成 error 结果，不让整轮聊天挂掉', () async {
    final completer = _FakeCompleter([_wantsWeather('Chengdu'), _plain('稍后再试。')]);
    final api = ChatApiService(
      completer: completer,
      weatherLookup: (city, {lang = 'en'}) async => throw Exception('down'),
    );

    final reply = await api.chat(history, 'en');

    expect(reply, '稍后再试。');
    final toolMessage = completer.sentMessages[1].last;
    expect(
      jsonDecode(toolMessage['content'] as String),
      {'error': 'failed to fetch weather'},
    );
  });

  test('未知工具名 → 不去查天气，直接回一个 error 结果', () async {
    final completer = _FakeCompleter([
      _wantsWeather('Chengdu', name: 'book_hotel'),
      _plain('好'),
    ]);
    var weatherCalled = false;
    final api = ChatApiService(
      completer: completer,
      weatherLookup: (city, {lang = 'en'}) async {
        weatherCalled = true;
        return {};
      },
    );

    await api.chat(history, 'en');

    expect(weatherCalled, isFalse);
    final toolMessage = completer.sentMessages[1].last;
    expect(jsonDecode(toolMessage['content'] as String), {'error': 'unknown tool'});
  });
}
