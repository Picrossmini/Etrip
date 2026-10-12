import 'package:etrip/core/utils/app_router.dart';
import 'package:etrip/features/auth/data/services/local_storage_service.dart';
import 'package:etrip/features/onbording/presentation/views/on_bording_view.dart';
import 'package:etrip/features/splash/presentation/views/splash_view.dart';
import 'package:etrip/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_fonts.dart';
import 'widget/support/itinerary_widget_harness.dart';

/// 冒烟：App 起得来吗。
///
/// 这里原来是一句 `expect(true, isTrue)`，等于没测——一个永远为真的断言，
/// App 入口整个崩掉它照样绿。现在真的把 `MyApp` 挂起来跑一遍：主题、路由、
/// Bloc 接线、Hive 的盒子、启动落地页，哪一环坏了这条都会红。
///
/// 闪屏落地有两条分支（登录过 → 主界面，没登录 → 引导页）。真机上两条都要走，
/// 写在 `integration_test/app_flows_test.dart` 里；CI 里没有设备，跑不了那份，
/// 这里就只覆盖「盒子是空的 → 落到引导页」。
///
/// 跑法：`flutter test test/widget_test.dart`
void main() {
  setUpAll(() async {
    // 跟 lib/main.dart 一样，只是 Hive 落到临时目录、字体走假的
    await setUpWidgetTestEnvironment();
    await setUpFakeGoogleFontsAssets();
    await LocalStorageService.init();
  });

  testWidgets('冒烟：启动后从闪屏落到引导页', (tester) async {
    // 竖屏手机尺寸：`SizeConfig.defaultSize` 依赖 MediaQuery 的宽高
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    AppRouter.router.go('/'); // 静态路由，拨回根路径保证从闪屏开始
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.byType(SplashView), findsOneWidget);

    // 闪屏里是 4 秒的 Future.delayed + 一个 repeat(reverse: true) 的循环动画，
    // pumpAndSettle 会一直等下去，只能按时间推。
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(OnBordingView), findsOneWidget);
  });
}
