import 'package:etrip/core/utils/size_config.dart';
import 'package:etrip/features/places/data/models/place_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:etrip/core/localization/locale_cubit.dart';
import 'package:etrip/core/mock_data.dart';
import 'featured_slider_item.dart';

class FeatureSlider extends StatelessWidget {
  final double? height;
  final double? width;
  final String? imageAsset;
  final List<PlaceModel>? places;
  final void Function(PlaceModel? place)? onTap;

  const FeatureSlider({
    super.key,
    this.height,
    this.width,
    this.imageAsset,
    this.places,
    this.onTap,
  }) : assert(
            (imageAsset != null && places == null) ||
                (imageAsset == null && places != null),
            'Either imageAsset or places must be provided, but not both.',
          );

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final uniquePlaces = places != null
        ? (places!
            .fold<Map<String, PlaceModel>>(
              {},
              (map, place) {
                if (!map.containsKey(place.name)) {
                  map[place.name] = place;
                }
                return map;
              },
            ).values.toList())
        : null;

    return Container(
      padding: const EdgeInsets.only(left: 8),
      height: height ?? SizeConfig.defaultSize! * 20,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: uniquePlaces != null ? uniquePlaces.length : 5,
        itemBuilder: (context, index) {
          if (uniquePlaces != null) {
            final place = uniquePlaces[index];
            return FeaturedSliderItem(
              width: width,
              imageUrl: (place.profileImage.isNotEmpty)
                        ? place.profileImage
                        :  place.carouselImages.first,
              isStatic: false,
              cityName: localizedCityName(place.cityName, lang),
              name: localizedPlaceName(place, lang),
              rate: place.rate,
              placeId: place.id,
              category: localizedCategory(place.category, lang),
              tourismType: localizedTourismType(place.tourismType, lang),
              description: place.description,
              nameEn: place.name,
              cityEn: place.cityName,
              categoryEn: place.category,
              tourismTypeEn: place.tourismType,
              descriptionEn: place.description,
              googleMapsLink: place.googleMapsLink,
              totalRates: place.totalRates,
              carousel: place.carouselImages,
              onTap: () => onTap?.call(place),
            );
          } else {
            return FeaturedSliderItem(
              width: width,
              imageAsset: imageAsset!,
              isStatic: true,
              onTap: () => onTap?.call(null),
            );
          }
        },
      ),
    );
  }
}