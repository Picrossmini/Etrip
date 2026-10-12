import 'package:etrip/features/Itinerary/data/models/itinerary_response.dart';
import 'package:etrip/features/places/data/models/place_model.dart';

/// 把「按天分组的景点 id」水合成真实的 [PlaceModel]，并按顺序重新编号 1..N。
///
/// 两条生成路径共用它：
/// - 直连大模型（[LlmPlanParser]）：模型返回 `days[].place_ids`；
/// - 自建后端（[BackendTravelPlanGenerator]）：后端返回 `days[].places[].place_id`。
///
/// 生成的行程必须能正常展示，所以：
/// - 未知 id 直接丢弃（模型可能编造 id —— 尤其是后端那条路径，
///   后端并不认识客户端本地目录，只能靠模型照着提示词里的目录挑）；
/// - 某天一个都没匹配上时，用目录里还没用过的景点兜底，保证每天非空。
class PlanHydrator {
  const PlanHydrator();

  ItineraryResponse hydrate({
    required List<List<String>> dayPlaceIds,
    required String description,
    required List<PlaceModel> catalog,
  }) {
    final byId = <String, PlaceModel>{for (final p in catalog) p.id: p};
    final plan = <int, List<PlaceModel>>{};
    final usedIds = <String>{};

    var dayNumber = 1;
    for (final ids in dayPlaceIds) {
      final places = <PlaceModel>[];
      for (final id in ids) {
        final place = byId[id];
        if (place != null) {
          places.add(place);
          usedIds.add(place.id);
        }
      }
      if (places.isEmpty && catalog.isNotEmpty) {
        final fallback = catalog.firstWhere(
          (p) => !usedIds.contains(p.id),
          orElse: () => catalog.first,
        );
        places.add(fallback);
        usedIds.add(fallback.id);
      }
      plan[dayNumber] = places;
      dayNumber++;
    }

    return ItineraryResponse(
      noOfDays: plan.length,
      plan: plan,
      description: description,
    );
  }
}
