import 'package:etrip/features/Itinerary/data/models/saved_itinerary.dart';
import 'package:etrip/features/Itinerary/data/repositories/hive_itinerary_repository.dart';
import 'package:etrip/features/Itinerary/domain/itinerary_repository.dart';

/// 兼容旧调用点的静态门面（如 map_screen）。
///
/// 内部委托给可注入的 [ItineraryRepository] 实现。新代码应直接依赖
/// [ItineraryRepository]（便于测试注入），不要再调用这里的静态方法。
class ItineraryStorageService {
  static final ItineraryRepository _repository = HiveItineraryRepository();

  static Future<void> save(SavedItinerary itinerary) =>
      _repository.save(itinerary);

  static Future<List<SavedItinerary>> loadAll(String userId) =>
      _repository.loadAll(userId);

  static Future<void> delete(String userId, String itineraryId) =>
      _repository.delete(userId, itineraryId);
}
