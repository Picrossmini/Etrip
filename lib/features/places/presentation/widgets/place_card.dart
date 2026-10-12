import 'package:etrip/core/widgets/app_image.dart';
import 'package:etrip/core/widgets/custom_star_rating_widget.dart';
import 'package:etrip/features/places/data/models/place_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:etrip/features/wishlist/data/model/favorite_model.dart';
import 'package:etrip/features/wishlist/presentation/views/widgets/favorite_icon.dart';
import 'package:etrip/core/widgets/space_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:etrip/core/localization/locale_cubit.dart';
import 'package:etrip/core/mock_data.dart';

class PlaceCard extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback? onTap;

  PlaceCard({super.key, required this.place, this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleCubit>().state.languageCode;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AppImage(
                    (place.profileImage.isNotEmpty
                        ? place.profileImage
                        : place.carouselImages.first),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        localizedCategory(place.category, lang),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 99, 99, 99),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FavoriteIcon(
                        iconSize: 30,
                        id: place.id,
                        type: FavoriteType.place,
                        title: place.name,
                        imageUrl: place.profileImage,
                        city: place.cityName,
                        category: place.category,
                        rate: place.rate.toString(),
                        tourismType: place.tourismType,
                        description: place.description,
                        googleMapsLink: place.googleMapsLink,
                        totalRates: place.totalRates,
                        carousel: place.carouselImages,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedPlaceName(place, lang),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.travel_explore,
                          size: 17,
                          color: Color.fromARGB(255, 25, 37, 106),
                        ),
                        const HorizantalSpace(0.3),
                        Text(
                          localizedTourismType(place.tourismType, lang),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromARGB(255, 119, 119, 119),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.place,
                                color: Color.fromARGB(255, 25, 37, 106),
                                size: 19),
                            const HorizantalSpace(0.15),
                            Text(
                              localizedCityName(place.cityName, lang),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color.fromARGB(255, 119, 119, 119),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            CustomStarRatingWidget(rating: place.rate),
                            const HorizantalSpace(0.3),
                            Text(
                              place.rate.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 119, 119, 119),
                              ),
                            ),
                            const HorizantalSpace(0.3),
                            Text(
                              "(${place.totalRates})",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 119, 119, 119),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}