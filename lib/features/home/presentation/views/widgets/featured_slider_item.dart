import 'package:etrip/core/widgets/app_image.dart';
import 'package:etrip/features/wishlist/data/model/favorite_model.dart';
import 'package:etrip/features/wishlist/presentation/views/widgets/favorite_icon.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:etrip/core/widgets/space_widget.dart';

class FeaturedSliderItem extends StatelessWidget {
  final double? width;
  final String? imageAsset;
  final String? imageUrl;
  final bool isStatic;
  final String? cityName;
  final String? name;
  final double? rate;
  final String? placeId;
  final String? category;
  final String? tourismType;
  final VoidCallback? onTap;
  final String? description;

  // English canonical values stored into favorites (display uses the localized
  // fields above; storage stays language-independent).
  final String? nameEn;
  final String? cityEn;
  final String? categoryEn;
  final String? tourismTypeEn;
  final String? descriptionEn;

  final String? googleMapsLink;

  final int? totalRates;

  final List<dynamic>? carousel;

  const FeaturedSliderItem({
    super.key,
    this.width,
    this.imageAsset,
    this.imageUrl,
    required this.isStatic,
    this.cityName,
    this.name,
    this.rate,
    this.placeId,
    this.category,
    this.tourismType,
    this.onTap,
    this.description,
    this.nameEn,
    this.cityEn,
    this.categoryEn,
    this.tourismTypeEn,
    this.descriptionEn,
    this.googleMapsLink,
    this.totalRates,
    this.carousel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 150,
        height: 200,
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isStatic
                  ? Image.asset(
                      imageAsset!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : AppImage(
                      imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
            if (cityName != null && name != null && rate != null) ...[
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name!,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cityName ?? '',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              double rating = rate ?? 0;

                              if (rating > 4.5) {
                                rating = 5.0;
                              } else if (rating > 4.0) {
                                rating = 4.5;
                              }

                              if (rating >= index + 1) {
                                return const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              } else if (rating > index && rating < index + 1) {
                                return const Icon(
                                  Icons.star_half,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              } else {
                                return const Icon(
                                  Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }
                            }),
                          ),
                          const HorizantalSpace(0.3),
                          Text(
                            '(${rate!.toStringAsFixed(1)})',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (!isStatic && placeId != null && placeId!.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: FavoriteIcon(
                    iconSize: 30,
                    id: placeId!,
                    type: FavoriteType.place,
                    title: nameEn ?? name ?? '',
                    imageUrl: imageUrl ?? '',
                    city: cityEn ?? cityName ?? '',
                    category: categoryEn ?? category ?? '',
                    rate: rate?.toString() ?? '0.0',
                    tourismType: tourismTypeEn ?? tourismType ?? '',
                    description: descriptionEn ?? description ?? '',
                    googleMapsLink: googleMapsLink ?? '',
                    totalRates: totalRates ?? 0,
                    carousel: carousel ?? [],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
