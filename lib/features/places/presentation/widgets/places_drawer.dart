import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:etrip/core/widgets/custom_buttons.dart';
import 'package:etrip/core/localization/translations.dart';
import 'package:etrip/core/localization/locale_cubit.dart';
import 'package:etrip/core/mock_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlacesDrawer extends StatelessWidget {
  final List<String> cities;
  final List<String> tourismTypes;
  final List<String> popularityOptions;
  final String? selectedCity;
  final String? selectedTourismType;
  final String? selectedPopularity;
  final void Function(String?)? onCityChange;
  final void Function(String?)? onTourismTypeChange;
  final void Function(String?)? onPopularityChange;
  final VoidCallback onClear;
  final VoidCallback onApply;

  const PlacesDrawer({
    super.key,
    required this.cities,
    required this.tourismTypes,
    required this.popularityOptions,
    required this.selectedCity,
    required this.selectedTourismType,
    required this.selectedPopularity,
    required this.onCityChange,
    required this.onTourismTypeChange,
    required this.onPopularityChange,
    required this.onClear,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleCubit>().state.languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            Translations.tr('filter_by', lang),
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // City
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: Translations.tr('city', lang),
                border: const OutlineInputBorder(),
              ),
              value: selectedCity,
              items: cities
                  .map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(localizedCityName(city, lang),
                            style: GoogleFonts.playfairDisplay(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                      ))
                  .toList(),
              onChanged: onCityChange,
            ),
          ),
          const SizedBox(height: 16),
          // Tourism Type
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: Translations.tr('tourism_type', lang),
                border: const OutlineInputBorder(),
              ),
              value: selectedTourismType,
              items: tourismTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(Translations.trTourismType(type, lang),
                        style: GoogleFonts.playfairDisplay(),
                            overflow: TextOverflow.ellipsis, maxLines: 1),
                      ))
                  .toList(),
              onChanged: onTourismTypeChange,
            ),
          ),
          const SizedBox(height: 16),
          // Popularity
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: Translations.tr('popularity', lang),
                border: const OutlineInputBorder(),
              ),
              value: selectedPopularity,
              items: popularityOptions
                  .map((popularity) => DropdownMenuItem(
                        value: popularity,
                        child: Text(
                            Translations.tr(
                                popularity == 'All' ? 'all' : popularity, lang),
                            style: GoogleFonts.playfairDisplay(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                      ))
                  .toList(),
              onChanged: onPopularityChange,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomJoinButton(text: Translations.tr('clear', lang), onTap: onClear, fontSize: 18),
              CustomJoinButton(text: Translations.tr('apply', lang), onTap: onApply, fontSize: 18),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
