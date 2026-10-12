import 'package:etrip/features/places/data/models/place_model.dart';
import 'package:etrip/features/places/data/places_api_service.dart';
import 'package:etrip/features/places/presentation/widgets/place_card.dart';
import 'package:etrip/features/places/presentation/widgets/places_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:etrip/core/widgets/reusable_screen.dart';
import 'package:etrip/core/constants.dart';
import 'package:etrip/core/utils/app_router.dart';
import 'package:etrip/core/utils/size_config.dart';
import 'package:etrip/core/localization/translations.dart';
import 'package:etrip/core/localization/locale_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final PlacesApiService apiService = PlacesApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Futures
  late Future<Map<String, List<String>>> filterOptionsFuture;
  late Future<List<PlaceModel>> eventsFuture;
  static List<PlaceModel>? _cache;

  // Filters
  String? selectedCity;
  String? selectedTourismType;
  String? selectedPopularity;

  // Filter options
  List<String> cities = [];
  List<String> tourismTypes = [];
  List<String> popularityOptions = [];

  // All and filtered places
  List<PlaceModel> allPlaces = [];
  List<PlaceModel> displayedPlaces = [];

  @override
  void initState() {
    super.initState();
    filterOptionsFuture = apiService.fetchFilterOptions();
    eventsFuture = _getOrFetchPlaces();
  }

  Future<List<PlaceModel>> _getOrFetchPlaces() async {
    if (_cache != null && _cache!.isNotEmpty) {
      return _cache!;
    } else {
      _cache = await apiService.fetchAllPlaces();
      return _cache!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = GoRouterState.of(context);
    final extra = state.extra;
    if (extra is Map<String, dynamic> &&
        extra['tourism_type'] != null &&
        selectedTourismType == null) {
      selectedTourismType = extra['tourism_type'] as String;
      setState(() {
        eventsFuture = apiService.fetchAllPlaces();
      });
    }
  }

  List<PlaceModel> filterPlaces(List<PlaceModel> places) {
    return places.where((place) {
      final bool matchesCity =
          selectedCity == null || place.cityName == selectedCity;
      final bool matchesTourismType = selectedTourismType == null ||
          place.tourismType == selectedTourismType;
      final bool matchesPopularity = selectedPopularity == null ||
          selectedPopularity == 'All' ||
          place.category ==
              selectedPopularity; // غير شرط الشعبية لو عندك حاجة خاصة
      return matchesCity && matchesTourismType && matchesPopularity;
    }).toList();
  }

  void applyFilters() {
    setState(() {
      displayedPlaces = filterPlaces(allPlaces);
    });
    _scaffoldKey.currentState?.closeDrawer();
  }

  void clearFilters() {
    setState(() {
      selectedCity = null;
      selectedTourismType = null;
      selectedPopularity = null;
      displayedPlaces = List.from(allPlaces);
    });
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleCubit>().state.languageCode;
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: FutureBuilder<Map<String, List<String>>>(
          future: filterOptionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child: Text('${Translations.tr('error_loading_filters', lang)}${snapshot.error}'));
            }

            final data = snapshot.data ?? {};
            cities = data['cities'] ?? [];
            tourismTypes = data['tourismTypes'] ?? [];
            popularityOptions = data['popularity'] ?? [];

            return PlacesDrawer(
              cities: cities,
              tourismTypes: tourismTypes,
              popularityOptions: popularityOptions,
              selectedCity: selectedCity,
              selectedTourismType: selectedTourismType,
              selectedPopularity: selectedPopularity,
              onCityChange: (val) => setState(() => selectedCity = val),
              onTourismTypeChange: (val) =>
                  setState(() => selectedTourismType = val),
              onPopularityChange: (val) =>
                  setState(() => selectedPopularity = val),
              onClear: clearFilters,
              onApply: applyFilters,
            );
          },
        ),
      ),
      body: ReusableScreen(
        showBackButton: true,
        backgroundColor: kSecondaryColor,
        gradientStops: const [0.1, 0.7],
        imageColor: Colors.black,
        child: Padding(
          padding: EdgeInsets.only(top: SizeConfig.defaultSize! * 8),
          child: FutureBuilder<List<PlaceModel>>(
            future: eventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('${Translations.tr('error', lang)}: ${snapshot.error}'));
              }
              if (allPlaces.isEmpty && snapshot.hasData) {
                allPlaces = snapshot.data!;
                displayedPlaces = filterPlaces(allPlaces);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Translations.tr('places_title', lang),
                          style: TextStyle(
                            fontSize: SizeConfig.defaultSize! * 3.25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                offset: Offset(3, 3),
                                blurRadius: 4,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune, color: Colors.white),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayedPlaces.length,
                      itemBuilder: (context, index) {
                        final place = displayedPlaces[index];
                        return PlaceCard(
                          place: place,
                          onTap: () {
                            context.push(AppRouter.kPlaceDetails, extra: place);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
