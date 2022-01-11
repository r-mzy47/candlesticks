import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/theme/color_palette.dart';
import 'package:flutter/material.dart';

class CandleInfoText extends StatelessWidget {
  const CandleInfoText({
    Key? key,
    required this.candle,
  }) : super(key: key);

  final Candle candle;

  String numberFormat(int value) {
    return "${value < 10 ? 0 : ""}$value";
  }

  String dateFormatter(DateTime date) {
    return "${date.year}-${numberFormat(date.month)}-${numberFormat(date.day)} ${numberFormat(date.hour)}:${numberFormat(date.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: dateFormatter(candle.date),
        style: TextStyle(color: ColorPalette.grayColor, fontSize: 10),
        children: <TextSpan>[
          TextSpan(text: " O:"),
          TextSpan(
              text: candle.open.toStringAsFixed(2),
              style: TextStyle(
                  color:
                      candle.isBull ? ColorPalette.green : ColorPalette.red)),
          TextSpan(text: " H:"),
          TextSpan(
              text: candle.high.toStringAsFixed(2),
              style: TextStyle(
                  color:
                      candle.isBull ? ColorPalette.green : ColorPalette.red)),
          TextSpan(text: " L:"),
          TextSpan(
              text: candle.low.toStringAsFixed(2),
              style: TextStyle(
                  color:
                      candle.isBull ? ColorPalette.green : ColorPalette.red)),
          TextSpan(text: " C:"),
          TextSpan(
              text: candle.close.toStringAsFixed(2),
              style: TextStyle(
                  color:
                      candle.isBull ? ColorPalette.green : ColorPalette.red)),
        ],
      ),
    );
  }
}
