import 'package:etrip/features/Itinerary/data/models/itinerary_request.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_response.dart';

/// 抽象：行程生成器。
///
/// 这是方案 4.4 要求的「可注入接口」——调用方（页面/控制器）只能依赖这个
/// 抽象，不能直接 new 具体实现，否则测试时无法替换成固定夹具。
///
///   TravelPlanGenerator
///     ├─ BackendTravelPlanGenerator（生产默认：走自建后端，密钥不在客户端）
///     ├─ LlmTravelPlanGenerator    （直连 DeepSeek；仅冒烟用例与本地调试用）
///     └─ MockTravelPlanGenerator   （离线/演示实现）
///
/// 测试里再注入 FakeTravelPlanGenerator（见 test/support）。
abstract class TravelPlanGenerator {
  Future<ItineraryResponse> generate({
    required String userId,
    required ItineraryRequest request,
  });
}

/// 生成过程中「可预期失败」的统一异常类型。
///
/// 页面只需捕获这一个类型就能给出友好提示，不必关心底层是超时、
/// 网络错误还是模型返回了脏数据。
class ItineraryGenerationException implements Exception {
  final String message;
  final Object? cause;

  const ItineraryGenerationException(this.message, {this.cause});

  @override
  String toString() => 'ItineraryGenerationException: $message';
}
