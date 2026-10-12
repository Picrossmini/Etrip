import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:etrip/core/localization/locale_cubit.dart';
import 'package:etrip/core/localization/translations.dart';
import 'package:etrip/core/utils/app_router.dart';
import 'package:etrip/features/Itinerary/data/generators/backend_travel_plan_generator.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_request.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_response.dart';
import 'package:etrip/features/Itinerary/data/repositories/hive_itinerary_repository.dart';
import 'package:etrip/features/Itinerary/domain/itinerary_generation_controller.dart';
import 'package:etrip/features/Itinerary/domain/itinerary_repository.dart';
import 'package:etrip/features/Itinerary/domain/travel_plan_generator.dart';
import 'package:etrip/features/places/data/models/place_model.dart';
import 'package:etrip/features/places/presentation/widgets/place_card.dart';
import 'package:etrip/features/auth/data/services/local_storage_service.dart';

class ItineraryResultView extends StatefulWidget {
  final Map<String, dynamic> args;
  final VoidCallback? onStartNew;

  /// 可注入依赖：默认走自建后端 + Hive 仓储。
  final TravelPlanGenerator? generator;
  final ItineraryRepository? repository;

  const ItineraryResultView({
    super.key,
    required this.args,
    this.onStartNew,
    this.generator,
    this.repository,
  });

  @override
  State<ItineraryResultView> createState() => _ItineraryResultViewState();
}

class _ItineraryResultViewState extends State<ItineraryResultView> {
  ItineraryGenerationController? _controller;
  ItineraryResponse? _savedResponse;
  late final String _uid;
  bool _isSavedView = false;

  @override
  void initState() {
    super.initState();
    _uid = LocalStorageService().currentUid ?? '';

    if (widget.args.containsKey('_savedPlaces')) {
      _isSavedView = true;
      _savedResponse = _buildSavedResponse();
    } else {
      final controller = ItineraryGenerationController(
        generator: widget.generator ?? BackendTravelPlanGenerator(),
        repository: widget.repository ?? HiveItineraryRepository(),
      );
      _controller = controller;
      controller.generate(userId: _uid, request: _buildRequest());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  ItineraryRequest _buildRequest() => ItineraryRequest(
        noOfDays: widget.args['noOfDays'],
        categoryWeights: {for (var e in widget.args['categoryWeights']) e: 1},
        tourismTypeWeights: {
          for (var e in widget.args['tourismTypeWeights']) e: 1
        },
        budget: widget.args['budget'],
        popularity: widget.args['popularity'],
        withWho: widget.args['withWho'],
        city: widget.args['city'] ?? '',
      );

  ItineraryResponse _buildSavedResponse() {
    final places = widget.args['_savedPlaces'] as List<PlaceModel>;
    final noOfDays = widget.args['noOfDays'] as int;
    final plan = <int, List<PlaceModel>>{};
    for (int day = 1; day <= noOfDays; day++) {
      final start = (day - 1) * 2;
      final end = start + 2;
      plan[day] = start < places.length
          ? places.sublist(start, end.clamp(0, places.length))
          : [];
    }
    return ItineraryResponse(noOfDays: noOfDays, plan: plan, description: '');
  }

  void _retry() {
    _controller?.generate(userId: _uid, request: _buildRequest());
  }

  void _goBack() {
    widget.onStartNew?.call();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleCubit>().state.languageCode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 200) {
            _goBack();
          }
        },
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 237, 239, 241), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                AppBar(
                  title: Text(
                    '${Translations.tr('day', lang)} 1-${widget.args['noOfDays']}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _goBack,
                  ),
                ),
                Expanded(child: _body(lang)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(String lang) {
    if (_isSavedView) {
      return _planList(_savedResponse!, lang);
    }
    final controller = _controller!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.hasError) {
          return _errorView(controller, lang);
        }
        final response = controller.response;
        if (response == null) {
          return const SizedBox.shrink();
        }
        return _planList(response, lang);
      },
    );
  }

  Widget _errorView(ItineraryGenerationController controller, String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              Translations.tr('error', lang),
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${controller.error}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: Text(Translations.tr('create_itinerary', lang)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              Translations.tr('no_plan_generated', lang),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planList(ItineraryResponse resp, String lang) {
    final hasAnyPlace = resp.plan.values.any((places) => places.isNotEmpty);
    if (!hasAnyPlace) {
      return _emptyView(lang);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (resp.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              resp.description,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ...resp.plan.entries.expand((entry) => [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "${Translations.tr('day', lang)} ${entry.key}",
                  style: GoogleFonts.montserrat(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2544)),
                ),
              ),
              ...entry.value.map((place) => PlaceCard(
                    place: place,
                    onTap: () {
                      context.push(AppRouter.kPlaceDetails, extra: place);
                    },
                  )),
              const Divider(),
            ]),
      ],
    );
  }
}
