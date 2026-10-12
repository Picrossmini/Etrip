import 'dart:convert';

import 'package:hive/hive.dart';

import 'package:etrip/features/Itinerary/data/models/saved_itinerary.dart';
import 'package:etrip/features/Itinerary/domain/itinerary_repository.dart';

/// 真实实现：基于 Hive 的本地持久化。
///
/// 逻辑与原来 ItineraryStorageService 完全一致，只是从静态方法改成实例方法，
/// 从而可以作为一个 [ItineraryRepository] 被注入。
class HiveItineraryRepository implements ItineraryRepository {
  static const String _boxName = 'saved_itineraries';

  Box<String>? _box;

  Future<Box<String>> get _instance async {
    final existing = _box;
    if (existing != null && existing.isOpen) return existing;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  static String _key(String userId) => 'itineraries_$userId';

  @override
  Future<void> save(SavedItinerary itinerary) async {
    final box = await _instance;
    final key = _key(itinerary.userId);
    final list = _decode(box.get(key));
    list.add(itinerary);
    await box.put(key, _encode(list));
  }

  @override
  Future<List<SavedItinerary>> loadAll(String userId) async {
    final box = await _instance;
    final list = _decode(box.get(_key(userId)));
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> delete(String userId, String itineraryId) async {
    final box = await _instance;
    final key = _key(userId);
    final list = _decode(box.get(key));
    list.removeWhere((i) => i.id == itineraryId);
    await box.put(key, _encode(list));
  }

  static String _encode(List<SavedItinerary> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<SavedItinerary> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> arr = jsonDecode(raw) as List<dynamic>;
    return arr
        .map((e) => SavedItinerary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
