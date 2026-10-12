import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:etrip/core/config.dart';
import 'package:etrip/core/utils/utf8_body.dart';
import 'package:etrip/features/chat_bot/domain/chat_completer.dart';

/// 走后端（etrip-backend 的 `POST /api/chat`）做单轮补全。
///
/// 取代了原先客户端直连 DeepSeek 的写法，目的只有一个：**DeepSeek 密钥不再进
/// 客户端**。它只存在于服务端的环境变量里，客户端带的是一个访问令牌。
///
/// 后端刻意只做「透传」：工具（查天气）的定义还是客户端提供、也在客户端执行，
/// 后端不解释 `tools`，只是跟 messages 一起转给模型，再把这一条助手消息原样还回来。
/// 所以工具循环仍旧在客户端（见 `ChatApiService.chat`）。
class BackendChatCompleter implements ChatCompleter {
  final http.Client client;
  final String baseUrl;
  final String? token;
  final Duration timeout;
  final int maxTokens;

  /// 后端给上游 30s（`DEEPSEEK_TIMEOUT`），客户端要比它宽松，
  /// 否则会出现「服务端还在等模型、客户端已经超时」的假超时。
  static const Duration _defaultTimeout = Duration(seconds: 40);

  static const int _defaultMaxTokens = 600;

  BackendChatCompleter({
    http.Client? client,
    String? baseUrl,
    String? token,
    this.timeout = _defaultTimeout,
    this.maxTokens = _defaultMaxTokens,
  })  : client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.backendBaseUrl,
        token = token ?? AppConfig.backendToken;

  @override
  Future<ChatCompletion> complete({
    required List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
  }) async {
    final uri = Uri.parse('$baseUrl/api/chat');

    final http.Response response;
    try {
      response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              if (token != null && token!.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode(buildBody(messages, tools: tools)),
          )
          .timeout(timeout);
    } on TimeoutException catch (e) {
      throw ChatException('请求超时，请稍后重试', cause: e);
    } on http.ClientException catch (e) {
      throw ChatException('网络连接失败，请检查网络后重试', cause: e);
    }

    if (response.statusCode != 200) {
      throw ChatException(
        _errorMessage(response),
        cause: decodeUtf8Body(response),
      );
    }

    return parseBody(decodeUtf8Body(response));
  }

  /// 组装请求体。`tools` 为空时整个字段都不发（后端也允许省略）。
  Map<String, dynamic> buildBody(
    List<Map<String, dynamic>> messages, {
    List<Map<String, dynamic>>? tools,
  }) =>
      {
        'messages': messages,
        if (tools != null && tools.isNotEmpty) 'tools': tools,
        'max_tokens': maxTokens,
      };

  /// 解析响应体。格式见后端 README 的 `POST /api/chat`。
  ///
  /// 只取约定的字段，把模型偶尔多塞的东西丢掉 —— 这个 message 会被原样追加进
  /// 下一轮 messages，多一个字段就多一分被上游拒绝的风险。
  ChatCompletion parseBody(String responseBody) {
    Object? decoded;
    try {
      decoded = jsonDecode(responseBody);
    } catch (_) {
      throw const ChatException('服务返回的内容不是合法 JSON');
    }
    if (decoded is! Map) {
      throw const ChatException('服务返回的内容不是 JSON 对象');
    }

    final rawMessage = decoded['message'];
    if (rawMessage is! Map) {
      throw const ChatException('服务返回的内容缺少 message');
    }

    final message = <String, dynamic>{
      'role': rawMessage['role'] is String ? rawMessage['role'] : 'assistant',
      'content': rawMessage['content'] is String ? rawMessage['content'] : null,
    };

    final rawToolCalls = rawMessage['tool_calls'];
    if (rawToolCalls is List && rawToolCalls.isNotEmpty) {
      message['tool_calls'] = [
        for (final call in rawToolCalls)
          if (call is Map) _normalizeToolCall(call),
      ];
    }

    final finishReason =
        decoded['finish_reason'] is String ? decoded['finish_reason'] as String : 'stop';

    return ChatCompletion(message: message, finishReason: finishReason);
  }

  /// tool_calls 里 `id` 是关键：客户端靠它把工具结果（role=tool + tool_call_id）
  /// 接回对应的调用。缺了就当这次响应不合格 —— 后端其实已经拦过一道，这里再兜一层。
  static Map<String, dynamic> _normalizeToolCall(Map call) {
    final function = call['function'];
    final name = function is Map ? function['name'] : null;
    if (call['id'] == null || name == null) {
      throw const ChatException('模型返回的工具调用缺少 id 或函数名');
    }
    return {
      'id': call['id'].toString(),
      'type': call['type'] is String ? call['type'] : 'function',
      'function': {
        'name': name.toString(),
        'arguments': (function is Map ? function['arguments'] : null)?.toString() ?? '{}',
      },
    };
  }

  /// 后端所有错误都是 `{"error": {"code", "message", "details"}}`，
  /// 直接把 message 透出来；解析不出来才退回通用文案。
  static String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(decodeUtf8Body(response));
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map) {
          if (error['code'] == 'unauthorized') {
            return '访问令牌无效，请检查客户端配置';
          }
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message;
          }
        }
      }
    } catch (_) {
      // 响应体不是 JSON（比如网关直接返回 HTML），走下面的兜底文案。
    }
    return '服务暂时不可用（HTTP ${response.statusCode}）';
  }
}
