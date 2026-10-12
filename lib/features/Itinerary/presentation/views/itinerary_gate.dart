import 'package:flutter/material.dart';
import 'package:etrip/features/auth/data/services/local_storage_service.dart';
import 'package:etrip/features/Itinerary/data/repositories/hive_itinerary_repository.dart';
import 'package:etrip/features/Itinerary/domain/itinerary_repository.dart';
import 'package:etrip/features/Itinerary/domain/travel_plan_generator.dart';
import 'package:etrip/features/Itinerary/presentation/views/itinerary_step_one.dart';
import 'package:etrip/features/Itinerary/presentation/views/itinerary_result_view.dart';
import 'package:etrip/features/Itinerary/presentation/views/itinerary_home.dart';

enum _ItineraryMode { home, planning, result }

class ItineraryGate extends StatefulWidget {
  /// 可注入的生成器 / 仓储：默认用真实实现，测试时可传入假实现。
  final TravelPlanGenerator? generator;
  final ItineraryRepository? repository;

  const ItineraryGate({super.key, this.generator, this.repository});

  @override
  State<ItineraryGate> createState() => _ItineraryGateState();
}

class _ItineraryGateState extends State<ItineraryGate> {
  _ItineraryMode _mode = _ItineraryMode.home;
  Map<String, dynamic>? _args;
  String _userId = '';

  late final ItineraryRepository _repository =
      widget.repository ?? HiveItineraryRepository();

  @override
  void initState() {
    super.initState();
    _userId = LocalStorageService().currentUid ?? '';
  }

  void _startNew() {
    setState(() {
      _args = null;
      _mode = _ItineraryMode.planning;
    });
  }

  void _onStepOneDone(Map<String, dynamic> stepOneArgs) {
    setState(() {
      _args = {
        ...stepOneArgs,
        'categoryWeights': <String>[],
      };
      _mode = _ItineraryMode.result;
    });
  }

  void _onViewSaved(Map<String, dynamic> savedArgs) {
    setState(() {
      _args = savedArgs;
      _mode = _ItineraryMode.result;
    });
  }

  void _backToHome() {
    setState(() {
      _args = null;
      _mode = _ItineraryMode.home;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == _ItineraryMode.planning) {
      return ItineraryStepOne(onStepTwo: _onStepOneDone, onBack: _backToHome);
    }

    if (_mode == _ItineraryMode.result && _args != null) {
      return ItineraryResultView(
        args: _args!,
        onStartNew: _backToHome,
        generator: widget.generator,
        repository: _repository,
      );
    }

    // home mode
    return ItineraryHome(
      userId: _userId,
      repository: _repository,
      onNewItinerary: _startNew,
      onViewItinerary: _onViewSaved,
    );
  }
}
