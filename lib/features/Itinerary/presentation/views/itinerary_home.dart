import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:etrip/core/constants.dart';
import 'package:etrip/core/localization/locale_cubit.dart';
import 'package:etrip/core/localization/translations.dart';
import 'package:etrip/core/mock_data.dart';
import 'package:etrip/core/widgets/bamboo_texture.dart';
import 'package:etrip/core/widgets/space_widget.dart';
import 'package:etrip/features/Itinerary/data/models/saved_itinerary.dart';
import 'package:etrip/features/Itinerary/domain/itinerary_repository.dart';

class ItineraryHome extends StatefulWidget {
  final String userId;
  final ItineraryRepository repository;
  final VoidCallback onNewItinerary;
  final Function(Map<String, dynamic> args) onViewItinerary;

  const ItineraryHome({
    super.key,
    required this.userId,
    required this.repository,
    required this.onNewItinerary,
    required this.onViewItinerary,
  });

  @override
  State<ItineraryHome> createState() => _ItineraryHomeState();
}

class _ItineraryHomeState extends State<ItineraryHome> {
  int _refreshKey = 0;

  Future<void> _delete(String id) async {
    await widget.repository.delete(widget.userId, id);
    setState(() => _refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleCubit>().state.languageCode;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'new_itinerary',
        onPressed: widget.onNewItinerary,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: kSecondaryColor,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.6],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: BambooTexture(color: Colors.black),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const VerticalSpace(2),
                    Text(
                      Translations.tr('itinerary', lang),
                      style: GoogleFonts.merriweather(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const VerticalSpace(2),
                    Expanded(
                      child: FutureBuilder<List<SavedItinerary>>(
        key: ValueKey(_refreshKey),
        future: widget.repository.loadAll(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final itineraries = snapshot.data ?? [];
          if (itineraries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
                  const VerticalSpace(1),
                  Text(Translations.tr('no_itineraries', lang),
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const VerticalSpace(0.5),
                  Text(Translations.tr('tap_to_start', lang),
                      style: GoogleFonts.inter(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: itineraries.length,
            itemBuilder: (context, index) {
              final item = itineraries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final savedPlaces = mockPlaces
                        .where((p) => item.placeIds.contains(p.id))
                        .toList();
                    widget.onViewItinerary({
                      'noOfDays': item.noOfDays,
                      'city': item.city,
                      'budget': item.budget,
                      'withWho': item.withWho,
                      'popularity': 'medium',
                      'tourismTypeWeights': item.tourismTypes,
                      'categoryWeights': <String>[],
                      '_savedPlaces': savedPlaces,
                      '_savedId': item.id,
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${item.noOfDays}',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const HorizantalSpace(1.5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.noOfDays} ${Translations.tr('days', lang).toLowerCase()} · ${localizedCityName(item.city, lang)}',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                              const VerticalSpace(0.3),
                              Text(
                                '${Translations.tr('budget', lang)}: ${Translations.tr(item.budget, lang)} · ${Translations.tr('travel_with', lang)}: ${Translations.tr(item.withWho, lang)}',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _delete(item.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
