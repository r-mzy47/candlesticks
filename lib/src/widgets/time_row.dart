import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/theme/color_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TimeRow extends StatelessWidget {
  final List<Candle> candles;
  final double candleWidth;
  final ScrollController scrollController;

  const TimeRow({
    Key? key,
    required this.candles,
    required this.candleWidth,
    required this.scrollController,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    int step = 9;
    if (candleWidth < 3)
      step = 31;
    else if (candleWidth < 5)
      step = 19;
    else if (candleWidth < 7) step = 13;
    final dif = candles[0].date.difference(candles[step].date);
    return Padding(
      padding: const EdgeInsets.only(right: 51.0),
      child: ListView.builder(
        itemCount: candles.length,
        scrollDirection: Axis.horizontal,
        controller: scrollController,
        itemExtent: step * candleWidth,
        reverse: true,
        itemBuilder: (context, index) {
          int candleNumber = (step + 1) ~/ 2 - 10 + index * step + -1;
          DateTime? _time;
          if (candleNumber < 0)
            _time = candles[step + candleNumber].date.add(dif);
          else if (candleNumber < candles.length)
            _time = candles[candleNumber].date;
          else {
            final stepsBack = (candleNumber - candles.length) ~/ step + 1;
            final newIndex = candleNumber - stepsBack * step;
            _time = candles[newIndex].date.subtract(dif * stepsBack);
          }
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Container(
                  width: 0.5,
                  color: ColorPalette.grayColor,
                ),
              ),
              Text(
                "${_time.month}" + "/" + "${_time.day}",
                style: TextStyle(
                  color: ColorPalette.grayColor,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
