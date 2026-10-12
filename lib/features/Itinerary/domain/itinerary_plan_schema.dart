/// 大模型行程 JSON 的「结构契约」与结构断言。
///
/// 大模型输出不确定，同样的偏好两次返回内容不会完全一样，所以断言不能写
/// 「输出等于某某字符串」。业内做法是断**结构和约束**（schema 校验）：
/// 能解析、必填字段都在、类型正确、取值在合理范围。
///
/// 约定的大模型返回结构：
/// ```json
/// {
///   "description": "一句话概述",
///   "days": [
///     { "day": 1, "place_ids": ["1", "20"] },
///     { "day": 2, "place_ids": ["22"] }
///   ]
/// }
/// ```
class ItineraryPlanSchema {
  const ItineraryPlanSchema._();

  static const int minPlacesPerDay = 1;
  static const int maxPlacesPerDay = 8;

  /// 返回问题清单；空列表表示通过。
  ///
  /// [expectedDays] 为请求的天数，用于约束模型不要给超量的天数。
  static List<String> validate(Map<String, dynamic> json, {int? expectedDays}) {
    final problems = <String>[];

    final days = json['days'];
    if (days is! List || days.isEmpty) {
      problems.add('缺少非空的 days 列表');
      return problems; // 没有 days 无法继续校验
    }
    if (expectedDays != null && days.length > expectedDays) {
      problems.add('days 数量 ${days.length} 超过请求的 $expectedDays 天');
    }

    for (var i = 0; i < days.length; i++) {
      final item = days[i];
      if (item is! Map) {
        problems.add('第 ${i + 1} 天不是对象');
        continue;
      }
      final dayNo = asInt(item['day']);
      if (dayNo == null || dayNo < 1) {
        problems.add('第 ${i + 1} 天的 day 字段非法: ${item['day']}');
      }
      final ids = item['place_ids'];
      if (ids is! List || ids.isEmpty) {
        problems.add('第 ${i + 1} 天的 place_ids 为空或不是列表');
      } else if (ids.length > maxPlacesPerDay) {
        problems.add('第 ${i + 1} 天景点过多: ${ids.length}');
      }
    }

    final description = json['description'];
    if (description != null && description is! String) {
      problems.add('description 类型错误（应为字符串）');
    }

    return problems;
  }

  /// 容错地把值解析成 int（大模型有时会把数字写成字符串 "3"）。
  static int? asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
