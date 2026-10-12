import 'dart:io';

import 'package:etrip/core/localization/locale_cubit.dart';
import 'package:etrip/core/utils/size_config.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_response.dart';
import 'package:etrip/features/Itinerary/domain/itinerary_repository.dart';
import 'package:etrip/features/Itinerary/domain/travel_plan_generator.dart';
import 'package:etrip/features/Itinerary/presentation/views/itinerary_result_view.dart';
import 'package:etrip/features/places/data/models/place_model.dart';
import 'package:etrip/features/wishlist/data/service/favorite_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import '../../support/in_memory_itinerary_repository.dart';

/// 一次性准备测试环境：
/// - Hive 落到系统临时目录（不碰真实文件），并开好页面会用到的那几个盒子
/// - 关掉 google_fonts 的联网拉取，否则测试会去网上抓字体、又慢又飘
Future<void> setUpWidgetTestEnvironment() async {
  final dir = Directory.systemTemp.createTempSync('etrip_widget_test_');
  Hive.init(dir.path);

  // LocalStorageService.currentUid 读它
  await Hive.openBox('local_session');
  // LocaleCubit 读它
  await Hive.openBox('app_settings');
  // PlaceCard -> FavoriteIcon 在 build 里就会监听它
  await FavoriteService.initHive();

  GoogleFonts.config.allowRuntimeFetching = false;
}

/// 行程结果页需要的 args 形状（对应 ItineraryResultView._buildRequest）。
Map<String, dynamic> itineraryArgs({int noOfDays = 3}) => <String, dynamic>{
      'noOfDays': noOfDays,
      'categoryWeights': <String>['museum'],
      'tourismTypeWeights': <String>['Natural Attractions'],
      'budget': 'medium',
      'popularity': 'high',
      'withWho': 'solo',
      'city': 'Chengdu',
    };

/// 一份可控的行程结果：每天恰好一个景点，名字可预期。
ItineraryResponse responseWithDays(int days, {String description = 'sample'}) {
  final plan = <int, List<PlaceModel>>{};
  for (var day = 1; day <= days; day++) {
    plan[day] = [_place(day)];
  }
  return ItineraryResponse(
    noOfDays: days,
    plan: plan,
    description: description,
  );
}

PlaceModel _place(int index) => PlaceModel(
      id: 'p$index',
      name: 'Test Place $index',
      profileImage: 'https://example.com/p$index.jpg',
      carouselImages: ['https://example.com/p$index.jpg'],
      tourismType: 'Natural Attractions',
      category: 'park',
      cityName: 'Chengdu',
      rate: 4.5,
      totalRates: 10,
      description: 'desc',
      googleMapsLink: '',
    );

/// 把行程结果页挂起来：注入假的生成器与内存仓储，语言固定。
///
/// 顺带把测试画布设成竖屏手机尺寸——`SizeConfig.defaultSize` 依赖
/// MediaQuery 的宽高（`PlaceCard` 里的 `HorizantalSpace` 会直接 `value!`
/// 取它），不设的话宽高比一反，布局就崩。
///
/// [fontFamily] 只在出 golden 基准图时用：把主题字体换成一个真实加载进来的
/// 字族，否则文字会渲染成测试字体的方框，图看了也白看。
Future<void> pumpItineraryResultView(
  WidgetTester tester, {
  required TravelPlanGenerator generator,
  ItineraryRepository? repository,
  Map<String, dynamic>? args,
  String locale = 'en',
  String? fontFamily,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    BlocProvider<LocaleCubit>(
      create: (_) => LocaleCubit(
        initial: Locale(locale),
        restoreSaved: false,
      ),
      child: MaterialApp(
        locale: Locale(locale),
        theme: fontFamily == null ? null : ThemeData(fontFamily: fontFamily),
        supportedLocales: const [Locale('en'), Locale('zh')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            // App 里是在根部做这件事的，测试里补上
            SizeConfig().init(context);
            return ItineraryResultView(
              args: args ?? itineraryArgs(),
              generator: generator,
              repository: repository ?? InMemoryItineraryRepository(),
            );
          },
        ),
      ),
    ),
  );
}
