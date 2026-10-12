import 'dart:io';

import 'package:etrip/features/Itinerary/data/generators/llm_travel_plan_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_data.dart';

/// 方案 4.3：保留 1~2 条真实调用，只做冒烟。
///
/// 目的仅在于验证「接口没变、密钥还有效、模型还能通」，不校验内容质量；
/// 默认跳过，避免每次 CI 都花钱、变慢、因网络抖动假失败。
///
/// 密钥从环境变量读，**不再从 `AppConfig` 取** —— 客户端已经不带任何 DeepSeek
/// 密钥了（生产路径走自建后端），这条直连冒烟是唯一的例外，得手动喂一把。
///
/// 手动运行：RUN_LLM_SMOKE=true DEEPSEEK_API_KEY=sk-... flutter test test/smoke
void main() {
  final runSmoke = Platform.environment['RUN_LLM_SMOKE'] == 'true';
  final apiKey = Platform.environment['DEEPSEEK_API_KEY'] ?? '';

  test(
    '真实 DeepSeek 冒烟：密钥有效且返回可解析的结构化行程',
    () async {
      final generator = LlmTravelPlanGenerator(apiKey: apiKey);
      final resp = await generator.generate(
        userId: 'smoke-user',
        request: validRequest(noOfDays: 2, city: 'Chengdu'),
      );

      expect(resp.plan, isNotEmpty);
      expect(resp.noOfDays, greaterThan(0));
      expect(resp.plan.values.every((day) => day.isNotEmpty), isTrue);
    },
    skip: !runSmoke
        ? '默认跳过（真实调用有网络与费用成本）。设 RUN_LLM_SMOKE=true 后运行。'
        : (apiKey.isEmpty
            ? '设了 RUN_LLM_SMOKE=true 但没给 DEEPSEEK_API_KEY，没密钥没法直连。'
            : false),
  );
}
