import 'package:etrip/features/Itinerary/domain/itinerary_plan_schema.dart';
import 'package:etrip/features/places/data/models/place_model.dart';

class ItineraryResponse {
  final int noOfDays;
  final Map<int, List<PlaceModel>> plan;
  final String description;

  ItineraryResponse({
    required this.noOfDays,
    required this.plan,
    required this.description,
  });

  /// 容错反序列化：缺字段给默认值、类型不对尝试转换、未知字段忽略、
  /// 结构不合法时降级为空而不抛异常（方案 2.1「数据模型解析」）。
  factory ItineraryResponse.fromJson(Map<String, dynamic> json) {
    final plan = <int, List<PlaceModel>>{};
    final planJson = json['plan'];
    if (planJson is Map) {
      planJson.forEach((day, placesJson) {
        final dayNo = ItineraryPlanSchema.asInt(day);
        if (dayNo == null || placesJson is! List) return;
        plan[dayNo] = placesJson
            .whereType<Map>()
            .map((e) => PlaceModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    }
    return ItineraryResponse(
      noOfDays: ItineraryPlanSchema.asInt(json['no_of_days']) ?? plan.length,
      plan: plan,
      description: json['description']?.toString() ?? '',
    );
  }
}
