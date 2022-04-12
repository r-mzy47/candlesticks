import 'package:candlesticks_plus/src/models/candle.dart';
import 'package:candlesticks_plus/src/models/candle_style.dart';
import 'package:candlesticks_plus/src/theme/theme_data.dart';
import 'package:candlesticks_plus/src/utils/helper_functions.dart';
import 'package:flutter/material.dart';

class CandleInfoText extends StatelessWidget {
  final CandleStyle? candleStyle;
  final List<Candle> data;
  final bool showMa7, showMa25, showMa99;

  const CandleInfoText({
    Key? key,
    required this.candle,
    required this.data,
    this.candleStyle,
    this.showMa7 = false,
    this.showMa25 = false,
    this.showMa99 = false,
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
    final Color color = candleStyle != null
        ? (candle.isBull ? candleStyle!.bullColor : candleStyle!.bearColor)
        : (candle.isBull ? Theme.of(context).primaryGreen : Theme.of(context).primaryRed);

    final currentIndex = data.indexOf(candle);
    double ma7 = 0, ma25 = 0, ma99 = 0;
    if (data.length - 7 > currentIndex) {
      final list = data.sublist(currentIndex, currentIndex + 6).map((e) => e.close);
      ma7 = (list.fold<double>(0, (double p, double c) => p + c)) / list.length;
    }

    if (data.length - 25 > currentIndex) {
      final list = data.sublist(currentIndex, currentIndex + 24).map((e) => e.close);
      ma25 = (list.fold<double>(0, (double p, double c) => p + c)) / list.length;
    }

    if (data.length - 99 > currentIndex) {
      final list = data.sublist(currentIndex, currentIndex + 98).map((e) => e.close);
      ma99 = (list.fold<double>(0, (double p, double c) => p + c)) / list.length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: dateFormatter(candle.date),
            style: TextStyle(color: Theme.of(context).grayColor, fontSize: 14),
            children: <TextSpan>[
              TextSpan(text: "  Open: "),
              TextSpan(
                  text: HelperFunctions.priceToString(candle.open),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              TextSpan(text: "  High: "),
              TextSpan(
                  text: HelperFunctions.priceToString(candle.high),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              TextSpan(text: "  Low: "),
              TextSpan(
                  text: HelperFunctions.priceToString(candle.low),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              TextSpan(text: "  Close: "),
              TextSpan(
                  text: HelperFunctions.priceToString(candle.close),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(height: 4),
        RichText(
          text: TextSpan(
            text: '',
            style: TextStyle(color: Theme.of(context).grayColor, fontSize: 12),
            children: <TextSpan>[
              if (showMa7) ...[
                TextSpan(text: "MA(7): "),
                TextSpan(
                    text: HelperFunctions.priceToString(ma7) + '  ',
                    style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              ],
              if (showMa25) ...[
                TextSpan(text: "MA(25): "),
                TextSpan(
                    text: HelperFunctions.priceToString(ma25) + '  ',
                    style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
              ],
              if (showMa99) ...[
                TextSpan(text: "MA(99): "),
                TextSpan(
                    text: HelperFunctions.priceToString(ma99) + '  ',
                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
