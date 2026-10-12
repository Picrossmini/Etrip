import 'dart:convert';

import 'package:etrip/features/Itinerary/domain/itinerary_plan_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/llm_fixtures.dart';

void main() {
  group('ItineraryPlanSchema 结构断言', () {
    test('正常夹具：通过（无问题）', () {
      final json = jsonDecode(LlmFixtures.normal) as Map<String, dynamic>;
      expect(ItineraryPlanSchema.validate(json, expectedDays: 3), isEmpty);
    });

    test('缺少 days → 报告缺少非空 days 列表', () {
      final problems = ItineraryPlanSchema.validate({'description': 'x'});
      expect(problems, contains('缺少非空的 days 列表'));
    });

    test('天数超过请求天数 → 报告', () {
      final json = jsonDecode(LlmFixtures.tooLong(days: 30)) as Map<String, dynamic>;
      final problems = ItineraryPlanSchema.validate(json, expectedDays: 3);
      expect(problems.any((p) => p.contains('超过请求的 3 天')), isTrue);
    });

    test('某天 place_ids 为空 → 报告', () {
      final problems = ItineraryPlanSchema.validate({
        'days': [
          {'day': 1, 'place_ids': <String>[]},
        ],
      });
      expect(problems.any((p) => p.contains('place_ids 为空')), isTrue);
    });

    test('某天景点过多 → 报告', () {
      final problems = ItineraryPlanSchema.validate({
        'days': [
          {
            'day': 1,
            'place_ids': List.generate(9, (i) => '$i'),
          },
        ],
      });
      expect(problems.any((p) => p.contains('景点过多')), isTrue);
    });

    test('day 无法解析成整数 → 报告', () {
      final problems = ItineraryPlanSchema.validate({
        'days': [
          {'day': 'abc', 'place_ids': ['1']},
        ],
      });
      expect(problems.any((p) => p.contains('day 字段非法')), isTrue);
    });

    test('description 类型错误 → 报告', () {
      final problems = ItineraryPlanSchema.validate({
        'description': 123,
        'days': [
          {'day': 1, 'place_ids': ['1']},
        ],
      });
      expect(problems.any((p) => p.contains('description 类型错误')), isTrue);
    });

    test('asInt 容错：数字字符串与 num', () {
      expect(ItineraryPlanSchema.asInt('3'), 3);
      expect(ItineraryPlanSchema.asInt(3), 3);
      expect(ItineraryPlanSchema.asInt(3.0), 3);
      expect(ItineraryPlanSchema.asInt('x'), isNull);
    });
  });
}
