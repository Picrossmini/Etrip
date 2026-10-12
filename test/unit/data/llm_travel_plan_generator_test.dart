import 'package:etrip/core/mock_data.dart';
import 'package:etrip/features/Itinerary/data/generators/llm_travel_plan_generator.dart';
import 'package:etrip/features/Itinerary/domain/travel_plan_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/llm_fixtures.dart';
import '../../support/test_data.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

void main() {
  LlmTravelPlanGenerator genWith(
    MockClient client, {
    Duration timeout = const Duration(seconds: 5),
  }) =>
      LlmTravelPlanGenerator(
        client: client,
        apiKey: 'test-key',
        baseUrl: 'http://fake',
        timeout: timeout,
        catalog: mockPlaces,
      );

  test('正常 envelope → 返回可解析的行程', () async {
    final client = MockClient((req) async => http.Response(
        LlmFixtures.envelope(LlmFixtures.normal), 200,
        headers: _jsonHeaders));

    final resp = await genWith(client)
        .generate(userId: 'u', request: validRequest(noOfDays: 3));

    expect(resp.noOfDays, 3);
    expect(resp.plan[1]!.map((p) => p.id).toList(), ['1', '2']);
  });

  test('请求带上认证头与正确的 endpoint', () async {
    String? auth;
    Uri? url;
    final client = MockClient((req) async {
      auth = req.headers['Authorization'];
      url = req.url;
      return http.Response(LlmFixtures.envelope(LlmFixtures.normal), 200,
          headers: _jsonHeaders);
    });

    await genWith(client)
        .generate(userId: 'u', request: validRequest(noOfDays: 3));

    expect(auth, 'Bearer test-key');
    expect(url!.path, '/chat/completions');
  });

  test('非 200 → ItineraryGenerationException', () async {
    final client = MockClient(
        (req) async => http.Response('oops', 500, headers: _jsonHeaders));

    expect(
      () => genWith(client).generate(userId: 'u', request: validRequest()),
      throwsA(isA<ItineraryGenerationException>()),
    );
  });

  test('脏内容（非 JSON）→ ItineraryGenerationException', () async {
    final client = MockClient((req) async => http.Response(
        LlmFixtures.envelope(LlmFixtures.notJson), 200,
        headers: _jsonHeaders));

    expect(
      () => genWith(client).generate(userId: 'u', request: validRequest()),
      throwsA(isA<ItineraryGenerationException>()),
    );
  });

  test('超时 → ItineraryGenerationException', () async {
    final client = MockClient((req) async {
      await Future.delayed(const Duration(milliseconds: 300));
      return http.Response(LlmFixtures.envelope(LlmFixtures.normal), 200,
          headers: _jsonHeaders);
    });

    expect(
      () => genWith(client, timeout: const Duration(milliseconds: 20))
          .generate(userId: 'u', request: validRequest()),
      throwsA(isA<ItineraryGenerationException>()),
    );
  });

  test('网络异常 → ItineraryGenerationException', () async {
    final client = MockClient(
        (req) async => throw http.ClientException('no network'));

    expect(
      () => genWith(client).generate(userId: 'u', request: validRequest()),
      throwsA(isA<ItineraryGenerationException>()),
    );
  });
}
