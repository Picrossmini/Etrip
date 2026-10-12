import 'package:etrip/features/Itinerary/data/models/saved_itinerary.dart';
import 'package:etrip/features/Itinerary/domain/itinerary_repository.dart';

/// 测试替身：内存版仓储，不碰真实文件系统。
class InMemoryItineraryRepository implements ItineraryRepository {
  final Map<String, List<SavedItinerary>> _store = {};

  @override
  Future<void> save(SavedItinerary itinerary) async {
    (_store[itinerary.userId] ??= []).add(itinerary);
  }

  @override
  Future<List<SavedItinerary>> loadAll(String userId) async {
    final list = List<SavedItinerary>.from(_store[userId] ?? const []);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> delete(String userId, String itineraryId) async {
    _store[userId]?.removeWhere((i) => i.id == itineraryId);
  }
}
