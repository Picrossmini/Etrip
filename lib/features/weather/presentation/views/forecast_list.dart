import 'package:etrip/core/utils/size_config.dart';
import 'package:etrip/core/widgets/space_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ForecastList extends StatelessWidget {
  final List<Map<String, dynamic>> forecastData;

  const ForecastList({super.key, required this.forecastData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SizeConfig.defaultSize! * 15,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: forecastData.length,
        itemBuilder: (context, index) {
          var forecast = forecastData[index];
          return Card(
            color: Colors.white.withValues(alpha:0.2),
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(DateTime.parse(forecast['dateTime'])),
                    style: GoogleFonts.lato(color: Colors.white),
                  ),
                  const VerticalSpace(1),
                  // 图标套一层 Flexible：卡片高度是写死的（上面 defaultSize * 15），
                  // 而文字行高会随设备字体度量/系统字号变化——真机（2026-10-13 联调）
                  // 就是在这张卡里底部溢出 6.9px。给图标一个「可压缩」的弹性，
                  // 多出来的那点高度由它吃掉，文字变大也不会再顶出卡片。
                  // 内容装得下时它仍按原尺寸显示，视觉不变。
                  Flexible(
                    child: Image.network(
                      "https://openweathermap.org/img/wn/${forecast['icon']}@2x.png",
                      width: SizeConfig.defaultSize! * 5,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const VerticalSpace(1),
                  Text(
                    "${forecast['temperature'].toStringAsFixed(1)}°C",
                    style: GoogleFonts.lato(color: Colors.white),
                  ),
                  Text(
                    forecast['description'],
                    style: GoogleFonts.aclonica(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}