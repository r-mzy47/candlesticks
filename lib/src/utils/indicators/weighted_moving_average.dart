import 'dart:ui';
import 'package:candlesticks/candlesticks.dart';

class WeightedMovingAverageIndicator extends Indicator {
  WeightedMovingAverageIndicator({
    required int length,
    required Color color,
  }) : super(
          name: "WMA " + length.toString(),
          dependsOnNPrevCandles: length,
          calculator: (index, candles) {
            double sum = 0;
            for (int i = 0; i < length; i++) {
              sum += candles[i + index].close * (length - i);
            }
            return [sum / (length * (length + 1)) * 2];
          },
          indicatorComponentsStyles: [
            IndicatorStyle(name: "wmv", color: color),
          ],
        );
}
