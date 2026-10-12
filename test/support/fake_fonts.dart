import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// flutter_test 里给 google_fonts 铺的一套假资产。
///
/// google_fonts 找字体的路子是：先在资产清单（`AssetManifest.bin`）里找有没有
/// `assets/google_fonts/<Family>-<Weight>.ttf` 这种路径，有就从资产读，没有就联网
/// 下，两边都不行就抛异常。测试里既没有那些文件也不想联网，所以这里造一份假的
/// 清单 + 假的字体文件，让它安心走「资产里找到了」这条路。
///
/// **清单是在真清单基础上追加的，不能整个替换。** 踩过一次：替换之后所有真资产
/// （`assets/images/` 下的图）都会报 "Unable to load asset"，因为 mock handler 里
/// `return null` 并不会退回真实现，直接被当成「找不到」。
///
/// 代价：页面里用到清单里没有的字族/字重，google_fonts 会抛异常。真抛了就是
/// [_families] / [_weights] 缺一项，补上即可。
Future<void> setUpFakeGoogleFontsAssets() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // 真清单得在装 mock **之前**读，否则读到的是下面那份合成的
  final realManifest =
      const StandardMessageCodec().decodeMessage(
            await rootBundle.load('AssetManifest.bin'),
          )
          as Map<Object?, Object?>;

  final fontBytes = await _fontFixtureBytes();

  final manifest = const StandardMessageCodec().encodeMessage(<Object?, Object?>{
    ...realManifest,
    for (final family in _families)
      for (final weight in _weights)
        'assets/google_fonts/$family-$weight.ttf': <Object>[],
  });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
    final key = const StringCodec().decodeMessage(message);
    if (key == null) return null;

    if (key == 'AssetManifest.bin') return manifest;

    if (key.startsWith('assets/google_fonts/') && key.endsWith('.ttf')) {
      return fontBytes;
    }

    // 其余资产（图片等）从仓库里读。`PlatformAssetBundle` 送来的 key 是 URI 编码
    // 过的，带空格的文件名会变成 `page%20view%201.png`，所以要解一下码再试。
    for (final path in <String>[key, _decodeUri(key)]) {
      final file = File(path);
      if (file.existsSync()) {
        return ByteData.sublistView(file.readAsBytesSync());
      }
    }
    return null;
  });
}

/// 把测试用的中文字体注册成 [family]。
///
/// flutter_test 自带的字体没有汉字，字形会渲染成方框，golden 图看了也白看。
/// 用 [setUpFakeGoogleFontsAssets] 只能让 google_fonts「找到」一个字体文件，
/// 想在页面里真的用它，还得把字族注册进去。
///
/// 注意这份子集里拉丁字母也来自这个中日韩字库，字距跟真机上的 Inter 不一样，
/// 所以 golden 图只适合看「改完前后哪里动了」，别拿它评版面观感。
Future<void> loadTestFontAs(String family) async {
  final bytes = await _fontFixtureBytes();
  final loader = FontLoader(family)..addFont(Future<ByteData>.value(bytes));
  await loader.load();
}

/// 图标字体在测试里默认不加载，`Icon` 会画成方框。
/// 它随 SDK 一起躺在引擎缓存里，直接借来用，不用往仓库里塞副本。
/// 找不到就算了——图还是能出，只是图标是方框。
Future<void> loadMaterialIcons() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;

  final file = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!file.existsSync()) return;

  final loader = FontLoader('MaterialIcons')
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(file.readAsBytesSync())),
    );
  await loader.load();
}

/// 只给测试用的中文子集（Noto Sans CJK SC，合成方式写在 test/fixtures/README.md）。
/// 不进 pubspec、不进 App，只在测试里当替身。
const kTestFontFixture = 'test/fixtures/etrip_test_font_cjk.ttf';

Future<ByteData> _fontFixtureBytes() async => ByteData.sublistView(
      File(kTestFontFixture).readAsBytesSync(),
    );

String _decodeUri(String key) {
  try {
    return Uri.decodeFull(key);
  } catch (_) {
    return key;
  }
}

/// 页面里用到的字族。App 主题用的是 IM Fell French Canon SC，
/// 页面里零散用 Inter / Montserrat。
const _families = [
  'IM_Fell_French_Canon_SC',
  'IMFellFrenchCanonSC',
  'IM Fell French Canon SC',
  'Inter',
  'Montserrat',
  'Lato',
  'PlayfairDisplay',
];

/// 与 google_fonts 的 `_fontWeightToFilenameWeightParts` 对齐的字重名
/// （斜体那几个也顺手列上，够用）。
const _weights = [
  'Thin',
  'ExtraLight',
  'Light',
  'Regular',
  'Medium',
  'SemiBold',
  'Bold',
  'ExtraBold',
  'Black',
  'Italic',
  'RegularItalic',
  'SemiBoldItalic',
  'BoldItalic',
];
