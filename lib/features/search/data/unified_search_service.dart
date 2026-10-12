import 'search_item.dart';
import 'package:etrip/core/localization/translations.dart';
import 'package:etrip/core/mock_data.dart';
import 'package:etrip/features/places/data/models/place_model.dart';

class UnifiedSearchService {
  static List<SearchItem> search({
    required String query,
    required List<PlaceModel> places,
    String lang = 'en',
  }) {
    final q = query.toLowerCase();

    return places.where((p) {
      if (p.name.toLowerCase().contains(q)) return true;
      final zhName = placeNamesZh[p.id];
      if (zhName != null && zhName.toLowerCase().contains(q)) return true;
      return false;
    }).map((p) => SearchItem(
      id: p.id,
      type: "place",
      title: lang == 'zh' ? (placeNamesZh[p.id] ?? p.name) : p.name,
      imageUrl: p.profileImage.isNotEmpty ? p.profileImage : (p.carouselImages.isNotEmpty ? p.carouselImages.first : ""),
      city: lang == 'zh' ? (cityNamesZh[p.cityName] ?? p.cityName) : p.cityName,
      rating: p.rate.toString(),
      info: Translations.trCategory(p.category, lang),
    )).toList();
  }
}