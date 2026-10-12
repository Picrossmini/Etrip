import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:bloc/bloc.dart';

class LocaleCubit extends Cubit<Locale> {
  /// [initial] 与 [restoreSaved] 供测试注入：给固定语言、不碰 Hive。
  /// 默认参数保持原行为，App 里 `LocaleCubit()` 不受影响。
  LocaleCubit({
    Locale initial = const Locale('en'),
    bool restoreSaved = true,
  }) : super(initial) {
    if (restoreSaved) {
      _loadSavedLocale();
    }
  }

  static const String _boxName = 'app_settings';
  static const String _key = 'language_code';

  void _loadSavedLocale() {
    try {
      final box = Hive.box(_boxName);
      final code = box.get(_key, defaultValue: 'en');
      emit(Locale(code));
    } catch (_) {
      // Box might not be open yet
      Future.microtask(() async {
        try {
          final box = await Hive.openBox(_boxName);
          final code = box.get(_key, defaultValue: 'en');
          if (!isClosed) emit(Locale(code));
        } catch (_) {}
      });
    }
  }

  void setLanguage(String languageCode) {
    try {
      final box = Hive.box(_boxName);
      box.put(_key, languageCode);
    } catch (_) {
      Hive.openBox(_boxName).then((box) {
        box.put(_key, languageCode);
      });
    }
    emit(Locale(languageCode));
  }

  static Future<void> ensureBoxOpen() async {
    try {
      await Hive.openBox(_boxName);
    } catch (_) {}
  }
}
