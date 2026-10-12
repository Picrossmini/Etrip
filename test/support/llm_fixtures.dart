import 'dart:convert';

/// 大模型返回内容的测试夹具（方案 4.2 的七类）。
///
/// 全部是确定性的字符串，因此相关用例秒级跑完、不依赖网络。
class LlmFixtures {
  const LlmFixtures._();

  /// 1) 正常响应：标准 JSON，字段齐全。
  static const String normal = '{"description":"A cultural 3-day trip",'
      '"days":[{"day":1,"place_ids":["1","2"]},'
      '{"day":2,"place_ids":["4"]},'
      '{"day":3,"place_ids":["5","6"]}]}';

  /// 2) 缺字段：少了 description 与 no_of_days（应给默认值，不崩溃）。
  static const String missingFields =
      '{"days":[{"day":1,"place_ids":["1","20"]}]}';

  /// 3) 类型错误：day 返回成了字符串 "1"（应容错转换）。
  static const String wrongTypes =
      '{"description":"x","days":[{"day":"1","place_ids":["1"]},'
      '{"day":"2","place_ids":["20"]}]}';

  /// 4) 非法 JSON：自然语言 + markdown 代码块标记，应剥离标记后解析。
  static const String wrappedInProse =
      'Sure! Here is your plan:\n```json\n'
      '{"description":"ok","days":[{"day":1,"place_ids":["22"]}]}'
      '\n```\nEnjoy your trip!';

  /// 4b) 真正的非法内容：完全没有 JSON。
  static const String notJson = 'Sorry, I cannot help with that right now.';

  /// 5) 空响应。
  static const String empty = '';

  /// 6) 超长响应：30 天的行程。
  static String tooLong({int days = 30}) => jsonEncode({
        'description': 'A very long trip',
        'days': [
          for (var i = 1; i <= days; i++)
            {'day': i, 'place_ids': ['${(i % 30) + 1}']},
        ],
      });

  /// 7) 超时由 HTTP 层模拟（见 llm_travel_plan_generator_test），此处无需内容。

  /// 把助手文本包成 OpenAI 兼容的响应 envelope。
  static String envelope(String content) => jsonEncode({
        'choices': [
          {
            'message': {'role': 'assistant', 'content': content},
          },
        ],
      });

  static String envelopeMissingChoices = jsonEncode({'id': 'x'});
  static String envelopeEmptyContent = envelope('');
}
