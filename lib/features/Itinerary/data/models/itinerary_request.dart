import 'package:etrip/features/Itinerary/domain/itinerary_date_utils.dart';

class ItineraryRequest {
  /// 旅行天数上限（方案 3.2 边界值：0 非法、1 最小、30 上限、31 超限）。
  static const int maxDays = 30;

  /// 出行人数上限。
  static const int maxPeople = 20;

  static const List<String> budgets = ['low', 'medium', 'high'];
  static const List<String> popularities = ['low', 'medium', 'high'];
  static const List<String> companions = ['solo', 'friends', 'family', 'couple'];

  final int noOfDays;
  final Map<String, int> categoryWeights;
  final Map<String, int> tourismTypeWeights;
  final String budget;
  final String popularity;
  final String withWho;
  final String city;

  /// 以下为日期区间与人数，属于纯逻辑层字段（UI 后续接入），默认不参与现有流程。
  final int noOfPeople;
  final DateTime? startDate;
  final DateTime? endDate;

  ItineraryRequest({
    required this.noOfDays,
    required this.categoryWeights,
    required this.tourismTypeWeights,
    required this.budget,
    required this.popularity,
    required this.withWho,
    this.city = '',
    this.noOfPeople = 1,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() => {
        'no_of_days': noOfDays,
        'category_weights': categoryWeights,
        'tourism_type_weights': tourismTypeWeights,
        'budget': budget,
        'popularity': popularity,
        'with_who': withWho,
        'city': city,
        'no_of_people': noOfPeople,
        if (startDate != null) 'start_date': startDate!.toIso8601String(),
        if (endDate != null) 'end_date': endDate!.toIso8601String(),
      };

  /// 表单校验：返回错误清单，空列表表示合法（方案 2.1 / 3.1）。
  ///
  /// 控制器在发起生成请求前会先调用它 —— 非法请求不发请求（判定表规则 1~3）。
  List<String> validate() {
    final errors = <String>[];

    if (noOfDays < 1) {
      errors.add('旅行天数至少为 1 天');
    } else if (noOfDays > maxDays) {
      errors.add('旅行天数不能超过 $maxDays 天');
    }

    if (tourismTypeWeights.isEmpty) {
      errors.add('请至少选择一项旅行偏好');
    }

    if (noOfPeople < 1) {
      errors.add('出行人数至少为 1 人');
    } else if (noOfPeople > maxPeople) {
      errors.add('出行人数不能超过 $maxPeople 人');
    }

    if (city.trim().isEmpty) {
      errors.add('请选择目的地城市');
    }

    if (!budgets.contains(budget)) {
      errors.add('预算取值非法: $budget');
    }
    if (!popularities.contains(popularity)) {
      errors.add('热度取值非法: $popularity');
    }
    if (!companions.contains(withWho)) {
      errors.add('同行人取值非法: $withWho');
    }

    if (startDate != null && endDate != null) {
      if (!ItineraryDateUtils.isEndNotBeforeStart(startDate!, endDate!)) {
        errors.add('结束日期不能早于开始日期');
      } else {
        final derived =
            ItineraryDateUtils.daysBetweenInclusive(startDate!, endDate!);
        if (derived != noOfDays) {
          errors.add('日期区间共 $derived 天，与旅行天数 $noOfDays 不一致');
        }
      }
    }

    return errors;
  }
}
