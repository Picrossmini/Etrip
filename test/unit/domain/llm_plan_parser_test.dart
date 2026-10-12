import 'package:etrip/core/mock_data.dart';
import 'package:etrip/features/Itinerary/domain/llm_plan_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/llm_fixtures.dart';
import '../../support/test_data.dart';

void main() {
  const parser = LlmPlanParser();
  final catalog = mockPlaces;

  group('大模型返回的七类夹具（结构断言）', () {
    test('1) 正常响应 → 解析成功，天数与描述正确', () {
      final resp = parser.parse(
        LlmFixtures.normal,
        request: validRequest(noOfDays: 3),
        catalog: catalog,
      );
      expect(resp.noOfDays, 3);
      expect(resp.plan[1]!.map((p) => p.id).toList(), ['1', '2']);
      expect(resp.description, 'A cultural 3-day trip');
    });

    test('2) 缺字段 → 用默认值降级，不崩溃', () {
      final resp = parser.parse(
        LlmFixtures.missingFields,
        request: validRequest(noOfDays: 1),
        catalog: catalog,
      );
      expect(resp.noOfDays, 1);
      expect(resp.description, '');
      expect(resp.plan[1], isNotEmpty);
    });

    test('3) 类型错误（day 是字符串）→ 容错转换后解析成功', () {
      final resp = parser.parse(
        LlmFixtures.wrongTypes,
        request: validRequest(noOfDays: 2),
        catalog: catalog,
      );
      expect(resp.noOfDays, 2);
      expect(resp.plan[1]!.first.id, '1');
    });

    test('4) 非法 JSON（代码块标记 + 自然语言）→ 剥离后解析成功', () {
      final resp = parser.parse(
        LlmFixtures.wrappedInProse,
        request: validRequest(noOfDays: 1),
        catalog: catalog,
      );
      expect(resp.noOfDays, 1);
      expect(resp.plan[1]!.first.id, '22');
    });

    test('4b) 完全没有 JSON → 抛 ItineraryParseException', () {
      expect(
        () => parser.parse(LlmFixtures.notJson,
            request: validRequest(), catalog: catalog),
        throwsA(isA<ItineraryParseException>()),
      );
    });

    test('5) 空响应 → 抛 ItineraryParseException', () {
      expect(
        () => parser.parse(LlmFixtures.empty,
            request: validRequest(), catalog: catalog),
        throwsA(isA<ItineraryParseException>()),
      );
    });

    test('6) 超长响应（30 天）→ 全部解析，不卡死', () {
      final resp = parser.parse(
        LlmFixtures.tooLong(days: 30),
        request: validRequest(noOfDays: 30),
        catalog: catalog,
      );
      expect(resp.noOfDays, 30);
      expect(resp.plan.length, 30);
    });

    test('未知 place_id 被丢弃，且当天仍用目录兜底保证非空', () {
      final resp = parser.parse(
        '{"description":"x","days":[{"day":1,"place_ids":["does-not-exist"]}]}',
        request: validRequest(noOfDays: 1),
        catalog: catalog,
      );
      expect(resp.plan[1], isNotEmpty);
      expect(resp.plan[1]!.first.id, isNot('does-not-exist'));
    });
  });

  group('extractContent 取出助手文本', () {
    test('正常 envelope', () {
      expect(
        LlmPlanParser.extractContent(LlmFixtures.envelope('hello')),
        'hello',
      );
    });

    test('缺少 choices → 抛异常', () {
      expect(
        () => LlmPlanParser.extractContent(LlmFixtures.envelopeMissingChoices),
        throwsA(isA<ItineraryParseException>()),
      );
    });

    test('内容为空 → 抛异常', () {
      expect(
        () => LlmPlanParser.extractContent(LlmFixtures.envelopeEmptyContent),
        throwsA(isA<ItineraryParseException>()),
      );
    });
  });
}
