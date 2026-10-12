import 'dart:async';

import 'package:etrip/features/Itinerary/data/models/itinerary_request.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_response.dart';
import 'package:etrip/features/Itinerary/domain/travel_plan_generator.dart';

/// 测试替身：返回预先准备好的固定结果，并可统计被调用次数。
class FakeTravelPlanGenerator implements TravelPlanGenerator {
  ItineraryResponse? result;
  Object? error;
  Duration delay;
  int callCount = 0;

  /// 若提供，generate 会挂起直到它完成 —— 用来模拟「生成中」。
  Completer<void>? gate;

  FakeTravelPlanGenerator({
    this.result,
    this.error,
    this.delay = Duration.zero,
    this.gate,
  });

  @override
  Future<ItineraryResponse> generate({
    required String userId,
    required ItineraryRequest request,
  }) async {
    callCount++;
    if (gate != null) await gate!.future;
    if (delay > Duration.zero) await Future.delayed(delay);
    if (error != null) throw error!;
    return result!;
  }
}
