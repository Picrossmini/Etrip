import 'package:etrip/core/mock_data.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_request.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_response.dart';
import 'package:etrip/features/Itinerary/domain/travel_plan_generator.dart';

/// 离线/演示实现：不调大模型，用本地 mock 数据组装行程。
///
/// 保留它有两个作用：一是无网络时可作为可注入的备选实现；二是它完全确定性，
/// 适合需要稳定输出的测试。真实实现见 [LlmTravelPlanGenerator]。
class MockTravelPlanGenerator implements TravelPlanGenerator {
  final Duration latency;

  const MockTravelPlanGenerator({
    this.latency = const Duration(milliseconds: 300),
  });

  @override
  Future<ItineraryResponse> generate({
    required String userId,
    required ItineraryRequest request,
  }) async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    final types = request.tourismTypeWeights.keys.toList();
    return ItineraryResponse(
      noOfDays: request.noOfDays,
      plan: getMockItineraryPlan(
        request.noOfDays,
        city: request.city.isNotEmpty ? request.city : null,
        tourismTypes: types.isNotEmpty ? types : null,
      ),
      description:
          'A wonderful trip through China exploring cultural and natural highlights.',
    );
  }
}
