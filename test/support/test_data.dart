import 'package:etrip/core/mock_data.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_request.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_response.dart';

/// 一份通过校验的请求，供各用例按需覆盖字段。
ItineraryRequest validRequest({
  int noOfDays = 3,
  Map<String, int>? tourismTypeWeights,
  String city = 'Chengdu',
  String budget = 'medium',
  String popularity = 'high',
  String withWho = 'solo',
  int noOfPeople = 1,
  DateTime? startDate,
  DateTime? endDate,
}) =>
    ItineraryRequest(
      noOfDays: noOfDays,
      categoryWeights: const {},
      tourismTypeWeights:
          tourismTypeWeights ?? const {'Natural Attractions': 1},
      budget: budget,
      popularity: popularity,
      withWho: withWho,
      city: city,
      noOfPeople: noOfPeople,
      startDate: startDate,
      endDate: endDate,
    );

/// 一份简单的行程结果，供控制器 / 生成器用例使用。
ItineraryResponse sampleResponse({int days = 1}) => ItineraryResponse(
      noOfDays: days,
      plan: {
        for (var d = 1; d <= days; d++)
          d: [mockPlaces[(d - 1) % mockPlaces.length]],
      },
      description: 'sample',
    );
