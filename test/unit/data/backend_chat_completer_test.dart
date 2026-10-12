import 'dart:convert';

import 'package:etrip/features/chat_bot/data/backend_chat_completer.dart';
import 'package:etrip/features/chat_bot/domain/chat_completer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

/// 后端 `POST /api/chat` 的成功响应（结构见 etrip-backend/README.md）。
String chatBody({
  Object? content = '成都很适合春天去。',
  List<Map<String, dynamic>>? toolCalls,
  String finishReason = 'stop',
}) =>
    jsonEncode({
      'request_id': 'req-1',
      'message': {
        'role': 'assistant',
        'content': content,
        if (toolCalls != null) 'tool_calls': toolCalls,
      },
      'finish_reason': finishReason,
    });

String errorBody(String code, String message) =>
    jsonEncode({'error': {'code': code, 'message': message, 'details': null}});

Map<String, dynamic> weatherCall({String id = 'call_weather_1'}) => {
      'id': id,
      'type': 'function',
      'function': {'name': 'get_weather', 'arguments': '{"city": "成都"}'},
    };

void main() {
  BackendChatCompleter completerWith(
    MockClient client, {
    Duration timeout = const Duration(seconds: 5),
  }) =>
      BackendChatCompleter(
        client: client,
        baseUrl: 'http://fake',
        token: 'test-token',
        timeout: timeout,
      );

  test('正常回复 → 拿到助手消息与 finish_reason', () async {
    final completer = completerWith(MockClient(
        (req) async => http.Response(chatBody(), 200, headers: _jsonHeaders)));

    final result = await completer.complete(messages: [
      {'role': 'user', 'content': '成都有什么好玩的？'}
    ]);

    expect(result.content, '成都很适合春天去。');
    expect(result.finishReason, 'stop');
    expect(result.message['role'], 'assistant');
    expect(result.wantsTools, isFalse);
  });

  test('请求打到 /api/chat，带 Bearer 令牌，body 形状对', () async {
    late http.Request captured;
    final completer = completerWith(MockClient((req) async {
      captured = req;
      return http.Response(chatBody(), 200, headers: _jsonHeaders);
    }));

    final messages = [
      {'role': 'system', 'content': '你是 Etrip 助手'},
      {'role': 'user', 'content': '你好'},
    ];
    final tools = [
      {'type': 'function', 'function': {'name': 'get_weather'}}
    ];
    await completer.complete(messages: messages, tools: tools);

    expect(captured.url.toString(), 'http://fake/api/chat');
    expect(captured.headers['Authorization'], 'Bearer test-token');

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['messages'], messages);
    expect(body['tools'], tools);
    expect(body['max_tokens'], 600);
  });

  test('tools 为空时整个字段都不发', () async {
    late http.Request captured;
    final completer = completerWith(MockClient((req) async {
      captured = req;
      return http.Response(chatBody(), 200, headers: _jsonHeaders);
    }));

    await completer.complete(messages: [
      {'role': 'user', 'content': 'hi'}
    ], tools: const []);

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body.containsKey('tools'), isFalse);
  });

  test('max_tokens 可配置', () async {
    late http.Request captured;
    final completer = BackendChatCompleter(
      client: MockClient((req) async {
        captured = req;
        return http.Response(chatBody(), 200, headers: _jsonHeaders);
      }),
      baseUrl: 'http://fake',
      token: 'test-token',
      maxTokens: 1500,
    );

    await completer.complete(messages: [
      {'role': 'user', 'content': 'hi'}
    ]);

    expect(
      (jsonDecode(captured.body) as Map)['max_tokens'],
      1500,
    );
  });

  test('模型要求调工具 → tool_calls 连同 id 原样带回', () async {
    final completer = completerWith(MockClient((req) async => http.Response(
        chatBody(content: null, toolCalls: [weatherCall()], finishReason: 'tool_calls'),
        200,
        headers: _jsonHeaders)));

    final result = await completer.complete(messages: [
      {'role': 'user', 'content': '成都今天天气怎么样？'}
    ]);

    expect(result.finishReason, 'tool_calls');
    expect(result.content, '');
    expect(result.wantsTools, isTrue);

    final call = result.toolCalls.single;
    expect(call['id'], 'call_weather_1');
    expect(call['type'], 'function');
    expect(call['function']['name'], 'get_weather');
    expect(call['function']['arguments'], '{"city": "成都"}');
  });

  test('只保留约定字段：模型多塞的 reasoning_content / index 一律丢掉', () async {
    final messy = {
      'request_id': 'req-1',
      'message': {
        'role': 'assistant',
        'content': '',
        'reasoning_content': '（思考过程，不该回传）',
        'tool_calls': [
          {
            'index': 0,
            'id': 'call_1',
            'type': 'function',
            'function': {
              'name': 'get_weather',
              'arguments': '{"city":"成都"}',
            },
          }
        ],
      },
      'finish_reason': 'tool_calls',
    };
    final completer = completerWith(MockClient(
        (req) async => http.Response(jsonEncode(messy), 200, headers: _jsonHeaders)));

    final result = await completer.complete(messages: [
      {'role': 'user', 'content': 'hi'}
    ]);

    expect(result.message.keys.toSet(), {'role', 'content', 'tool_calls'});
    expect(result.toolCalls.single.keys.toSet(), {'id', 'type', 'function'});
    expect(
      (result.toolCalls.single['function'] as Map).keys.toSet(),
      {'name', 'arguments'},
    );
  });

  test('工具调用缺 id → 抛 ChatException（接不回结果就别用）', () async {
    final broken = {
      'message': {
        'role': 'assistant',
        'content': '',
        'tool_calls': [
          {
            'type': 'function',
            'function': {'name': 'get_weather'},
          }
        ],
      },
      'finish_reason': 'tool_calls',
    };
    final completer = completerWith(MockClient(
        (req) async => http.Response(jsonEncode(broken), 200, headers: _jsonHeaders)));

    expect(
      () => completer.complete(messages: [
        {'role': 'user', 'content': 'hi'}
      ]),
      throwsA(isA<ChatException>()),
    );
  });

  test('401 → 提示令牌无效', () async {
    final completer = completerWith(MockClient((req) async => http.Response(
        errorBody('unauthorized', 'invalid token'), 401,
        headers: _jsonHeaders)));

    await expectLater(
      completer.complete(messages: [
        {'role': 'user', 'content': 'hi'}
      ]),
      throwsA(isA<ChatException>().having(
          (e) => e.message, 'message', contains('令牌'))),
    );
  });

  test('400 业务错 → 把后端 message 透出来', () async {
    final completer = completerWith(MockClient((req) async => http.Response(
        errorBody('invalid_request', 'messages 不能为空'), 400,
        headers: _jsonHeaders)));

    await expectLater(
      completer.complete(messages: [
        {'role': 'user', 'content': 'hi'}
      ]),
      throwsA(isA<ChatException>().having(
          (e) => e.message, 'message', 'messages 不能为空')),
    );
  });

  test('非 JSON 的 502 → 退回通用文案', () async {
    final completer = completerWith(MockClient(
        (req) async => http.Response('<html>bad gateway</html>', 502)));

    await expectLater(
      completer.complete(messages: [
        {'role': 'user', 'content': 'hi'}
      ]),
      throwsA(isA<ChatException>().having(
          (e) => e.message, 'message', contains('502'))),
    );
  });

  test('超时 → ChatException', () async {
    final completer = completerWith(
      MockClient((req) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return http.Response(chatBody(), 200, headers: _jsonHeaders);
      }),
      timeout: const Duration(milliseconds: 50),
    );

    await expectLater(
      completer.complete(messages: [
        {'role': 'user', 'content': 'hi'}
      ]),
      throwsA(isA<ChatException>().having(
          (e) => e.message, 'message', contains('超时'))),
    );
  });

  test('网络错 → ChatException', () async {
    final completer = completerWith(
        MockClient((req) async => throw http.ClientException('boom')));

    await expectLater(
      completer.complete(messages: [
        {'role': 'user', 'content': 'hi'}
      ]),
      throwsA(isA<ChatException>().having(
          (e) => e.message, 'message', contains('网络'))),
    );
  });

  test('响应头不带 charset 时，中文也不会变成乱码', () async {
    // FastAPI 返回的正是 `application/json` 不带 charset；此时 http 包会按
    // latin1 解 body，中文会烂掉（成都 → æé½），所以必须自己按 UTF-8 解。
    final body = utf8.encode(chatBody(content: '成都很好玩，建议先去宽窄巷子。'));
    final completer = completerWith(MockClient((req) async =>
        http.Response.bytes(body, 200, headers: {'content-type': 'application/json'})));

    final result = await completer.complete(messages: [
      {'role': 'user', 'content': 'hi'}
    ]);

    expect(result.content, '成都很好玩，建议先去宽窄巷子。');
  });

  test('错误信息里的中文同样不乱码', () async {
    final body = utf8.encode(errorBody('invalid_request', 'messages 不能为空'));
    final completer = completerWith(MockClient((req) async =>
        http.Response.bytes(body, 400, headers: {'content-type': 'application/json'})));

    await expectLater(
      completer.complete(messages: [
        {'role': 'user', 'content': 'hi'}
      ]),
      throwsA(isA<ChatException>()
          .having((e) => e.message, 'message', 'messages 不能为空')),
    );
  });

  test('响应不是合法 JSON → ChatException', () async {
    final completer = completerWith(MockClient(
        (req) async => http.Response('not json at all', 200, headers: _jsonHeaders)));

    await expectLater(
      completer.complete(messages: [
        {'role': 'user', 'content': 'hi'}
      ]),
      throwsA(isA<ChatException>().having(
          (e) => e.message, 'message', contains('不是合法 JSON'))),
    );
  });

  test('响应缺少 message → ChatException', () async {
    final completer = completerWith(MockClient((req) async =>
        http.Response(jsonEncode({'request_id': 'req-1'}), 200,
            headers: _jsonHeaders)));

    await expectLater(
      completer.complete(messages: [
        {'role': 'user', 'content': 'hi'}
      ]),
      throwsA(isA<ChatException>().having(
          (e) => e.message, 'message', contains('缺少 message'))),
    );
  });
}
