import 'dart:async';

import 'package:etrip/core/localization/translations.dart';
import 'package:etrip/features/Itinerary/domain/travel_plan_generator.dart';
import 'package:etrip/features/places/presentation/widgets/place_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_travel_plan_generator.dart';
import 'support/itinerary_widget_harness.dart';

void main() {
  setUpAll(setUpWidgetTestEnvironment);

  testWidgets('生成中显示加载态，且还没有卡片', (tester) async {
    final gate = Completer<void>();
    final generator = FakeTravelPlanGenerator(gate: gate);

    await pumpItineraryResultView(tester, generator: generator);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PlaceCard), findsNothing);

    generator.result = responseWithDays(2);
    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(PlaceCard), findsNWidgets(2));
  });

  testWidgets('成功时渲染描述、每天的标题与景点卡片', (tester) async {
    final generator = FakeTravelPlanGenerator(result: responseWithDays(3));

    await pumpItineraryResultView(tester, generator: generator);
    await tester.pumpAndSettle();

    final dayWord = Translations.tr('day', 'en');
    expect(find.text('sample'), findsOneWidget);
    expect(find.text('$dayWord 1'), findsOneWidget);
    expect(find.text('$dayWord 2'), findsOneWidget);
    expect(find.byType(PlaceCard), findsWidgets);
    expect(find.text('Test Place 1'), findsOneWidget);

    // 第 3 天在首屏之外：往下滚能滚到，说明列表是通的、内容没丢
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('$dayWord 3'), findsOneWidget);
    expect(find.text('Test Place 3'), findsOneWidget);
  });

  testWidgets('失败时显示错误提示与重试按钮，而不是崩溃', (tester) async {
    final generator = FakeTravelPlanGenerator(
      error: const ItineraryGenerationException('模型超时'),
    );

    await pumpItineraryResultView(tester, generator: generator);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.text(Translations.tr('error', 'en')), findsOneWidget);
    expect(find.textContaining('模型超时'), findsOneWidget);
    expect(
      find.text(Translations.tr('create_itinerary', 'en')),
      findsOneWidget,
    );
    expect(find.byType(PlaceCard), findsNothing);
  });

  testWidgets('点重试会重新生成并渲染结果', (tester) async {
    final generator = FakeTravelPlanGenerator(
      error: const ItineraryGenerationException('第一次失败'),
    );

    await pumpItineraryResultView(tester, generator: generator);
    await tester.pumpAndSettle();
    expect(generator.callCount, 1);

    generator.error = null;
    generator.result = responseWithDays(1);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(generator.callCount, 2);
    expect(find.byType(PlaceCard), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsNothing);
  });

  testWidgets('空行程显示空状态，不是白屏', (tester) async {
    final generator = FakeTravelPlanGenerator(result: responseWithDays(0));

    await pumpItineraryResultView(tester, generator: generator);
    await tester.pumpAndSettle();

    expect(
      find.text(Translations.tr('no_plan_generated', 'en')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byType(PlaceCard), findsNothing);
  });

  testWidgets('中英文切换：标题文案随语言变化', (tester) async {
    // 前提：两种语言确实有不同文案，否则下面的断言没有意义
    expect(
      Translations.tr('day', 'en'),
      isNot(Translations.tr('day', 'zh')),
    );

    final generator = FakeTravelPlanGenerator(result: responseWithDays(1));

    await pumpItineraryResultView(tester, generator: generator, locale: 'en');
    await tester.pumpAndSettle();
    expect(find.text('${Translations.tr('day', 'en')} 1'), findsOneWidget);

    // 先清空整棵树，否则 BlocProvider.create 不会重跑，语言还是 en
    await tester.pumpWidget(const SizedBox());
    await pumpItineraryResultView(tester, generator: generator, locale: 'zh');
    await tester.pumpAndSettle();
    expect(find.text('${Translations.tr('day', 'zh')} 1'), findsOneWidget);
    expect(find.text('${Translations.tr('day', 'en')} 1'), findsNothing);
  });

  testWidgets('空状态在中文下也显示中文', (tester) async {
    final generator = FakeTravelPlanGenerator(result: responseWithDays(0));

    await pumpItineraryResultView(
      tester,
      generator: generator,
      locale: 'zh',
    );
    await tester.pumpAndSettle();

    expect(
      find.text(Translations.tr('no_plan_generated', 'zh')),
      findsOneWidget,
    );
  });
}
