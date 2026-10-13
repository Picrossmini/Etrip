import 'package:etrip/core/utils/size_config.dart';
import 'package:etrip/features/weather/presentation/views/forecast_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// 一份形状与 OpenWeatherMap 解析结果一致的逐时预报数据。
List<Map<String, dynamic>> sampleForecast([int count = 3]) => <Map<String, dynamic>>[
      for (var i = 0; i < count; i++)
        <String, dynamic>{
          'dateTime': '2026-10-13 ${(9 + i * 3).toString().padLeft(2, '0')}:00:00',
          'icon': '01d',
          'temperature': 20.0 + i,
          'description': 'Sunny',
        },
    ];

/// 把 `ForecastList` 挂起来。
///
/// [textScale] 用来模拟系统字体放大——真机上那张卡片溢出就是被文字行高顶出去的。
Future<void> pumpForecastList(
  WidgetTester tester, {
  List<Map<String, dynamic>>? data,
  double textScale = 1.0,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;

  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  // 测试环境没有网络，`Image.network` 必定加载失败。那跟被测的布局无关，放过它；
  // 别的 FlutterError（尤其 RenderFlex 溢出）照旧上报、照旧让测试失败。
  final previous = FlutterError.onError!;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('NetworkImage') ||
        details.exceptionAsString().contains('statusCode: 400')) {
      return;
    }
    previous(details);
  };
  addTearDown(() => FlutterError.onError = previous);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          // App 里是在根部做这件事的，测试里补上：卡片高度全靠 defaultSize 换算
          SizeConfig().init(context);
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: ForecastList(forecastData: data ?? sampleForecast()),
            ),
          );
        },
      ),
    ),
  );
  // 网络图那一跳是异步的，多推一帧把它的失败耗掉（上面的过滤器还挂着）
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('渲染出每个时段的图标、时间、温度与描述', (tester) async {
    await pumpForecastList(tester, data: sampleForecast(3));

    expect(find.byType(Card), findsWidgets);
    expect(find.text('09:00 AM'), findsOneWidget);
    expect(find.text('20.0°C'), findsOneWidget);
    expect(find.text('Sunny'), findsWidgets);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('字体放大 1.5 倍时卡片不溢出（回归：真机曾溢出 6.9px）', (tester) async {
    // 卡片高度写死成 defaultSize * 15，文字一变大就会从底部顶出去。
    // 修法是给图标套 Flexible，让多出来的那点高度由它吃掉。
    await pumpForecastList(tester, data: sampleForecast(3), textScale: 1.5);

    // 有溢出的话 layout 期就会往 FlutterError 上报，测试即失败；
    // 能走到这里就说明卡片撑住了。
    expect(find.byType(Card), findsWidgets);
    expect(find.text('Sunny'), findsWidgets);
  });
}
