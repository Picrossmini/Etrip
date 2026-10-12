import 'dart:convert';

import 'package:etrip/core/mock_data.dart';
import 'package:etrip/features/Itinerary/data/generators/backend_travel_plan_generator.dart';
import 'package:etrip/features/Itinerary/domain/travel_plan_generator.dart';
import 'package:etrip/features/places/data/models/place_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/test_data.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

/// 后端 `POST /api/itinerary` 的成功响应（结构见 etrip-backend/README.md）。
String backendBody({
  String description = 'Chengdu in 3 days',
  List<List<String>> dayPlaceIds = const [
    ['1', '2'],
    ['4'],
    ['5', '6'],
  ],
}) =>
    jsonEncode({
      'request_id': 'req-1',
      'description': description,
      'from_cache': false,
      'days': [
        for (var i = 0; i < dayPlaceIds.length; i++)
          {
            'day': i + 1,
            'summary': 'Day ${i + 1}',
            'places': [
              for (final id in dayPlaceIds[i]) {'place_id': id, 'name': 'pm$id'},
            ],
          },
      ],
    });

String errorBody(String code, String message) =>
    jsonEncode({'error': {'code': code, 'message': message, 'details': null}});

void main() {
  BackendTravelPlanGenerator genWith(
    MockClient client, {
    Duration timeout = const Duration(seconds: 5),
    List<PlaceModel>? catalog,
  }) =>
      BackendTravelPlanGenerator(
        client: client,
        baseUrl: 'http://fake',
        token: 'test-token',
        timeout: timeout,
        catalog: catalog ?? mockPlaces,
      );

  MockClient okClient() => MockClient(
      (req) async => http.Response(backendBody(), 200, headers: _jsonHeaders));

  test('正常响应 → 水合成行程，且景点是完整的 PlaceModel', () async {
    final resp = await genWith(okClient())
        .generate(userId: 'u-1', request: validRequest(noOfDays: 3));

    expect(resp.noOfDays, 3);
    expect(resp.plan[1]!.map((p) => p.id).toList(), ['1', '2']);
    expect(resp.description, 'Chengdu in 3 days');

    // 关键：不只是 id，图片/评分/简介这些本地目录里的字段都要还在，
    // 否则行程页的景点卡片会变成空壳。
    final g = mockPlaces.firstWhere((p) => p.id == '1');
    expect(resp.plan[1]!.first.name, g.name);
    expect(resp.plan[1]!.first.profileImage, g.profileImage);
    expect(resp.plan[1]!.first.description, g.description);
  });

  test('响应头不带 charset 时，中文描述也不会变成乱码', () async {
    // 后端的 Content-Type 是 `application/json`（不带 charset），http 包会按
    // latin1 解 body，中文就烂了；必须自己按 UTF-8 解。
    final bytes = utf8.encode(backendBody(description: '成都三天，慢一点玩。'));
    final client = MockClient((req) async => http.Response.bytes(
        bytes, 200, headers: {'content-type': 'application/json'}));

    final resp = await genWith(client)
        .generate(userId: 'u-1', request: validRequest(noOfDays: 3));

    expect(resp.description, '成都三天，慢一点玩。');
  });

  test('请求打到 /api/itinerary，带 Bearer 令牌与正确的请求体', () async {
    Uri? url;
    String? auth;
    Map<String, dynamic>? body;
    final client = MockClient((req) async {
      url = req.url;
      auth = req.headers['Authorization'];
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(backendBody(), 200, headers: _jsonHeaders);
    });

    await genWith(client).generate(
      userId: 'u-1',
      request: validRequest(noOfDays: 3, city: 'Chengdu', noOfPeople: 2),
    );

    expect(url!.path, '/api/itinerary');
    expect(auth, 'Bearer test-token');

    expect(body!['user_id'], 'u-1');
    expect(body!['city'], 'Chengdu');
    expect(body!['tourism_types'], ['Natural Attractions']);
    expect(body!['days'], 3);
    expect(body!['no_of_people'], 2);
  });

  test('请求体里的 catalog 只带挑景点用得上的四个字段', () async {
    Map<String, dynamic>? body;
    final client = MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(backendBody(), 200, headers: _jsonHeaders);
    });

    await genWith(client)
        .generate(userId: 'u', request: validRequest(noOfDays: 3));

    final catalog = body!['catalog'] as List;
    expect(catalog, hasLength(mockPlaces.length));

    final first = catalog.first as Map;
    expect(
      first.keys.toSet(),
      {'place_id', 'name', 'city_name', 'tourism_type'},
      reason: '目录要进提示词，多余字段（图片、简介）只会白花 token',
    );
    expect(first['place_id'], mockPlaces.first.id);
    expect(first['name'], mockPlaces.first.name);
  });

  test('日期区间按后端要的 YYYY-MM-DD 传', () async {
    Map<String, dynamic>? body;
    final client = MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(backendBody(), 200, headers: _jsonHeaders);
    });

    await genWith(client).generate(
      userId: 'u',
      request: validRequest(
        noOfDays: 3,
        startDate: DateTime(2026, 10, 20),
        endDate: DateTime(2026, 10, 22),
      ),
    );

    expect(body!['start_date'], '2026-10-20');
    expect(body!['end_date'], '2026-10-22');
  });

  test('未登录（uid 为空）时补一个 anonymous，不白跑一趟 422', () async {
    Map<String, dynamic>? body;
    final client = MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(backendBody(), 200, headers: _jsonHeaders);
    });

    await genWith(client)
        .generate(userId: '', request: validRequest(noOfDays: 3));

    expect(body!['user_id'], 'anonymous');
  });

  test('后端返回未知 place_id → 丢弃，该天用目录兜底（不崩）', () async {
    final client = MockClient((req) async => http.Response(
        backendBody(dayPlaceIds: const [
          ['nope-1', 'nope-2'],
          ['4'],
        ]),
        200,
        headers: _jsonHeaders));

    final resp = await genWith(client)
        .generate(userId: 'u', request: validRequest(noOfDays: 2));

    expect(resp.plan[1], hasLength(1), reason: '每天至少要有 1 个景点');
    expect(mockPlaces.map((p) => p.id), contains(resp.plan[1]!.first.id));
  });

  test('本地目录为空 → 天保留但景点为空，不抛异常', () async {
    final resp = await genWith(okClient(), catalog: const [])
        .generate(userId: 'u', request: validRequest(noOfDays: 3));

    expect(resp.noOfDays, 3);
    expect(resp.plan[1], isEmpty);
  });

  test('401 → 提示访问令牌无效', () async {
    final client = MockClient((req) async => http.Response(
        errorBody('unauthorized', 'invalid token'), 401,
        headers: _jsonHeaders));

    expect(
      () => genWith(client).generate(userId: 'u', request: validRequest()),
      throwsA(isA<ItineraryGenerationException>().having(
        (e) => e.message,
        'message',
        '访问令牌无效，请检查客户端配置',
      )),
    );
  });

  test('400 → 把后端的业务错误文案透传给用户', () async {
    final client = MockClient((req) async => http.Response(
        errorBody('invalid_request', 'days 必须在 1..30 之间，收到 99'), 400,
        headers: _jsonHeaders));

    expect(
      () => genWith(client).generate(userId: 'u', request: validRequest()),
      throwsA(isA<ItineraryGenerationException>()
          .having((e) => e.message, 'message', contains('1..30'))),
    );
  });

  test('非 200 且响应体不是 JSON → 退回带状态码的兜底文案', () async {
    final client = MockClient(
        (req) async => http.Response('<html>502 Bad Gateway</html>', 502));

    expect(
      () => genWith(client).generate(userId: 'u', request: validRequest()),
      throwsA(isA<ItineraryGenerationException>()
          .having((e) => e.message, 'message', contains('502'))),
    );
  });

  test('响应缺少 days → ItineraryGenerationException', () async {
    final client = MockClient((req) async => http.Response(
        jsonEncode({'request_id': 'r', 'description': 'x'}), 200,
        headers: _jsonHeaders));

    expect(
      () => genWith(client).generate(userId: 'u', request: validRequest()),
      throwsA(isA<ItineraryGenerationException>()),
    );
  });

  test('响应不是合法 JSON → ItineraryGenerationException', () async {
    final client = MockClient(
        (req) async => http.Response('not json at all', 200,
            headers: _jsonHeaders));

    expect(
      () => genWith(client).generate(userId: 'u', request: validRequest()),
      throwsA(isA<ItineraryGenerationException>()),
    );
  });

  test('超时 → ItineraryGenerationException', () async {
    final client = MockClient((req) async {
      await Future.delayed(const Duration(milliseconds: 300));
      return http.Response(backendBody(), 200, headers: _jsonHeaders);
    });

    expect(
      () => genWith(client, timeout: const Duration(milliseconds: 20))
          .generate(userId: 'u', request: validRequest()),
      throwsA(isA<ItineraryGenerationException>()),
    );
  });

  test('网络异常 → ItineraryGenerationException', () async {
    final client =
        MockClient((req) async => throw http.ClientException('no network'));

    expect(
      () => genWith(client).generate(userId: 'u', request: validRequest()),
      throwsA(isA<ItineraryGenerationException>()),
    );
  });
}
