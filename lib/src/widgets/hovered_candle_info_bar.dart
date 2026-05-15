import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/widgets/candle_info_text.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:flutter/material.dart';

class HoveredCandleInfoBar extends StatelessWidget {
  const HoveredCandleInfoBar({
    super.key,
    required this.currentCandle,
  });

  final Candle? currentCandle;

  @override
  Widget build(BuildContext context) {
    final style = CandleSticksStyleProvider.of(context);

    return SizedBox(
      height: 20,
      child: currentCandle != null
          ? CandleInfoText(
              candle: currentCandle!,
              bullColor: style.primaryBull,
              bearColor: style.primaryBear,
              defaultStyle: TextStyle(
                color: style.primaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
