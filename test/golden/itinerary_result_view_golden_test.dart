@Tags(['golden'])
library;

import 'package:etrip/features/Itinerary/domain/travel_plan_generator.dart';
import 'package:etrip/features/Itinerary/presentation/views/itinerary_result_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../support/fake_fonts.dart';
import '../support/fake_travel_plan_generator.dart';
import '../widget/support/itinerary_widget_harness.dart';

/// 行程结果页的 golden 基准图。
///
/// **只在本地跑，不要接进 CI。** golden 比的是像素，跟平台的字形栅格化强相关：
/// Windows 上生成的图搬到 Linux runner 上会整体偏一点，天天误报，最后只会被
/// 大家习惯性 `--update-goldens` 掉，等于没测。它真正的用处是「改完这个页面，
/// 在本机前后对比一眼看出哪儿动了」。
///
/// 生成 / 更新基准图：
///   flutter test test/golden --update-goldens
///
/// 看基准图：`test/golden/goldens/*.png`，直接打开就行，里面是真字不是方框。
///
/// 一个前提要知道：图里的字是拿 `test/fixtures/` 里那份中文字库画的，拉丁字母
/// 也是它画的，字距和真机上的 Inter 不一样。所以这些图**只适合看「改完前后哪里
/// 动了」**——布局、间距、文案变没变、有没有漏出来一片白。别拿它评字体好不好看。
/// 等 google_fonts 把页面用到的字重真正装好，再把这一帧截下来。
///
/// 字体是从（假的）资产里**异步**读出来的，`pumpAndSettle` 不会等它；
/// 抢在装完之前截图，后出现的文字就会退回测试自带的方框字体——图上就是
/// 一排 `□□□`。踩过一次：同样一个页面上，先渲染的标题是真字，后渲染的
/// 空状态文案全是方框，查了半天以为是字库没这个字。
Future<void> _settleFonts(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await setUpWidgetTestEnvironment();
    await setUpFakeGoogleFontsAssets();
    await loadTestFontAs(_themeFont);
    await loadMaterialIcons();
  });

  testWidgets('golden: 英文 · 三天行程', (tester) async {
    final generator = FakeTravelPlanGenerator(result: responseWithDays(3));

    await pumpItineraryResultView(
      tester,
      generator: generator,
      locale: 'en',
      fontFamily: _themeFont,
    );
    await _settleFonts(tester);

    await expectLater(
      find.byType(ItineraryResultView),
      matchesGoldenFile('goldens/itinerary_result_en.png'),
    );
  });

  testWidgets('golden: 中文 · 三天行程', (tester) async {
    final generator = FakeTravelPlanGenerator(result: responseWithDays(3));

    await pumpItineraryResultView(
      tester,
      generator: generator,
      locale: 'zh',
      fontFamily: _themeFont,
    );
    await _settleFonts(tester);

    await expectLater(
      find.byType(ItineraryResultView),
      matchesGoldenFile('goldens/itinerary_result_zh.png'),
    );
  });

  testWidgets('golden: 中文 · 空行程（曾经是白屏）', (tester) async {
    final generator = FakeTravelPlanGenerator(result: responseWithDays(0));

    await pumpItineraryResultView(
      tester,
      generator: generator,
      locale: 'zh',
      fontFamily: _themeFont,
    );
    await _settleFonts(tester);

    await expectLater(
      find.byType(ItineraryResultView),
      matchesGoldenFile('goldens/itinerary_empty_zh.png'),
    );
  });

  testWidgets('golden: 中文 · 生成失败', (tester) async {
    final generator = FakeTravelPlanGenerator(
      error: const ItineraryGenerationException('模型超时，请稍后重试'),
    );

    await pumpItineraryResultView(
      tester,
      generator: generator,
      locale: 'zh',
      fontFamily: _themeFont,
    );
    await _settleFonts(tester);

    await expectLater(
      find.byType(ItineraryResultView),
      matchesGoldenFile('goldens/itinerary_error_zh.png'),
    );
  });
}

/// 页面里的字体换成这个真加载进来的字族，否则文字是测试字体的方框，图看了也白看。
/// 假资产 / 假字体那一套在 `test/support/fake_fonts.dart`，冒烟测试也用同一份。
const _themeFont = 'EtripTestFont';
