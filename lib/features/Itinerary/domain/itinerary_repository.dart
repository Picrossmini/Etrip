import 'package:etrip/features/Itinerary/data/models/saved_itinerary.dart';

/// 抽象：行程本地持久化。
///
/// 方案 4.4 要求的第二个可注入接口。真实实现是 Hive
/// （HiveItineraryRepository），测试里用内存实现（InMemoryItineraryRepository），
/// 这样持久化相关用例不必碰真实文件系统。
abstract class ItineraryRepository {
  Future<void> save(SavedItinerary itinerary);
  Future<List<SavedItinerary>> loadAll(String userId);
  Future<void> delete(String userId, String itineraryId);
}
