import 'package:flutter/foundation.dart';

import 'package:etrip/features/Itinerary/data/models/itinerary_request.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_response.dart';
import 'package:etrip/features/Itinerary/data/models/saved_itinerary.dart';
import 'package:etrip/features/Itinerary/domain/itinerary_repository.dart';
import 'package:etrip/features/Itinerary/domain/travel_plan_generator.dart';

/// 驱动「生成行程」这个动作：校验、加载态、防重复、错误重试、持久化。
///
/// 对应方案 3.3 的判定表：
/// - 规则 1~3：请求非法 → 直接返回错误，不调用生成器；
/// - 规则 4：正在生成中再次触发 → 被拦截（幂等，连点两次不会生成两份）；
/// - 规则 5：合法且空闲 → 进入加载态并发起请求；
/// - 规则 6：请求失败 → 记录错误、退出加载态、可重试。
class ItineraryGenerationController extends ChangeNotifier {
  final TravelPlanGenerator generator;
  final ItineraryRepository repository;

  bool isLoading = false;
  ItineraryResponse? response;
  Object? error;

  ItineraryGenerationController({
    required this.generator,
    required this.repository,
  });

  bool get hasError => error != null;
  bool get hasResponse => response != null;

  Future<void> generate({
    required String userId,
    required ItineraryRequest request,
  }) async {
    // 规则 4：生成中重复触发直接忽略。
    if (isLoading) return;

    // 规则 1~3：先校验，非法请求不发起。
    final problems = request.validate();
    if (problems.isNotEmpty) {
      error = ItineraryGenerationException(problems.join('；'));
      notifyListeners();
      return;
    }

    // 规则 5：进入加载态。
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await generator.generate(userId: userId, request: request);
      response = result;
      try {
        await _persist(userId, request, result);
      } catch (_) {
        // 持久化失败不影响本次结果的展示。
      }
    } catch (e) {
      // 规则 6：失败可重试（再次调用 generate 即可）。
      error = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    isLoading = false;
    response = null;
    error = null;
    notifyListeners();
  }

  Future<void> _persist(
    String userId,
    ItineraryRequest request,
    ItineraryResponse result,
  ) async {
    if (userId.isEmpty) return;
    final allPlaces = result.plan.values.expand((l) => l).toList();
    await repository.save(SavedItinerary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      createdAt: DateTime.now(),
      noOfDays: result.noOfDays,
      city: request.city,
      budget: request.budget,
      withWho: request.withWho,
      tourismTypes: request.tourismTypeWeights.keys.toList(),
      placeIds: allPlaces.map((p) => p.id).toList(),
    ));
  }
}
