import 'dart:io';

import 'package:etrip/features/Itinerary/data/generators/llm_travel_plan_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_data.dart';

/// 方案 4.3：保留 1~2 条真实调用，只做冒烟。
///
/// 目的仅在于验证「接口没变、密钥还有效、模型还能通」，不校验内容质量；
/// 默认跳过，避免每次 CI 都花钱、变慢、因网络抖动假失败。
///
/// 手动运行：RUN_LLM_SMOKE=true flutter test test/smoke
void main() {
  final runSmoke = Platform.environment['RUN_LLM_SMOKE'] == 'true';

  test(
    '真实 DeepSeek 冒烟：密钥有效且返回可解析的结构化行程',
    () async {
      final generator = LlmTravelPlanGenerator();
      final resp = await generator.generate(
        userId: 'smoke-user',
        request: validRequest(noOfDays: 2, city: 'Chengdu'),
      );

      expect(resp.plan, isNotEmpty);
      expect(resp.noOfDays, greaterThan(0));
      expect(resp.plan.values.every((day) => day.isNotEmpty), isTrue);
    },
    skip: runSmoke
        ? false
        : '默认跳过（真实调用有网络与费用成本）。设 RUN_LLM_SMOKE=true 后运行。',
  );
}
