// ignore_for_file: use_build_context_synchronously

import 'package:etrip/core/localization/locale_cubit.dart';
import 'package:etrip/core/localization/translations.dart';
import 'package:etrip/core/utils/app_router.dart';
import 'package:etrip/core/utils/size_config.dart';
import 'package:etrip/core/widgets/custom_buttons.dart';
import 'package:etrip/features/places/data/models/place_model.dart';
import 'package:etrip/core/widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:etrip/core/widgets/space_widget.dart';
import 'package:etrip/features/wishlist/data/model/favorite_model.dart';
import 'package:etrip/features/wishlist/data/service/favorite_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'favorite_icon.dart';
import 'package:go_router/go_router.dart';

class FavoriteCard extends StatelessWidget {
  final FavoriteType type;

  const FavoriteCard({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleCubit>().state.languageCode;
    return ValueListenableBuilder<Box<FavoriteModel>>(
      valueListenable:
          Hive.box<FavoriteModel>(FavoriteService.boxName).listenable(),
      builder: (context, box, _) {
        final favorites = box.values.where((fav) => fav.type == type).toList();

        if (favorites.isEmpty) {
          return Center(
            child: Text(
              Translations.tr('no_favorites_yet', lang),
              style:
                  GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          );
        }

        return ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final fav = favorites[index];

            return GestureDetector(
              onTap: () {
                final place = PlaceModel(
                  id: fav.id,
                  name: fav.title,
                  profileImage: fav.imageUrl,
                  carouselImages: (fav.carousel ?? []).cast<String>(),
                  tourismType: fav.tourismType ?? '',
                  category: fav.category ?? '',
                  cityName: fav.city,
                  rate: double.tryParse(fav.rate ?? '') ?? 0.0,
                  totalRates: fav.totalRates ?? 0,
                  description: fav.description ?? Translations.tr('description_not_available', lang),
                  googleMapsLink: fav.googleMapsLink ?? '',
                );
                context.push(AppRouter.kPlaceDetails, extra: place);
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 6.0,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  height: SizeConfig.defaultSize! * 24,
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AppImage(
                          fav.imageUrl,
                          width: SizeConfig.defaultSize! * 13,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const HorizantalSpace(1),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fav.title,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const VerticalSpace(0.5),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16),
                                const HorizantalSpace(0.5),
                                Expanded(
                                  child: Text(
                                    fav.city,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color.fromARGB(
                                          255, 119, 119, 119),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const VerticalSpace(0.4),
                            if (fav.category != null &&
                                fav.category!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.category, size: 16),
                                  const HorizantalSpace(0.5),
                                  Expanded(
                                    child: Text(
                                      '${Translations.tr('category_label', lang)}${fav.category}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            const VerticalSpace(0.5),
                            if (fav.tourismType != null &&
                                fav.tourismType!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.travel_explore, size: 16),
                                  const HorizantalSpace(0.5),
                                  Expanded(
                                    child: Tooltip(
                                      message: fav.tourismType ??
                                          Translations.tr('n_a', lang),
                                      child: Text(
                                        '${Translations.tr('type_label_short', lang)}${fav.tourismType != null && fav.tourismType!.isNotEmpty ? Translations.trTourismType(fav.tourismType!, lang) : Translations.tr('n_a', lang)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const VerticalSpace(0.5),
                            if (fav.rate != null && fav.rate!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 16, color: Colors.amber),
                                  const HorizantalSpace(0.5),
                                  Expanded(
                                    child: Text(
                                      '${Translations.tr('rating_label', lang)}${fav.rate}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomJoinButton(
                                    text: Translations.tr('explore_now', lang),
                                    onTap: () {
                                      final place = PlaceModel(
                                        id: fav.id,
                                        name: fav.title,
                                        profileImage: fav.imageUrl,
                                        carouselImages: (fav.carousel ?? [])
                                            .cast<String>(),
                                        tourismType: fav.tourismType ?? '',
                                        category: fav.category ?? '',
                                        cityName: fav.city,
                                        rate:
                                            double.tryParse(fav.rate ?? '') ??
                                                0.0,
                                        totalRates: fav.totalRates ?? 0,
                                        description: fav.description ??
                                            Translations.tr('description_not_available', lang),
                                        googleMapsLink:
                                            fav.googleMapsLink ?? '',
                                      );
                                      context.push(AppRouter.kPlaceDetails,
                                          extra: place);
                                    },
                                  ),
                                ),
                                const HorizantalSpace(0.5),
                                FavoriteIcon(
                                  id: fav.id,
                                  type: fav.type,
                                  title: fav.title,
                                  imageUrl: fav.imageUrl,
                                  additionalInfo: fav.additionalInfo,
                                  price: fav.price,
                                  city: fav.city,
                                  rate: fav.rate,
                                  category: fav.category,
                                  tourismType: fav.tourismType,
                                  description: fav.description,
                                  googleMapsLink: fav.googleMapsLink,
                                  totalRates: fav.totalRates,
                                  carousel: fav.carousel,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}