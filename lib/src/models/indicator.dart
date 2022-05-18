import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';

class Indicator {
  /// Indicator name. visible at top right side of chart
  final String name;

  /// Calculates indicator value for givien index.
  /// if your indicator has muliple lines (values) always return results in the same order.
  final List<double?> Function(int index, List<Candle> candles) calculator;
  final int dependsOnNPrevCandles;

  /// Indicator lines style.
  /// the order of this should be same as calculator function results order.
  final List<IndicatorStyle> indicatorComponentsStyles;

  Indicator({
    required this.name,
    required this.dependsOnNPrevCandles,
    required this.calculator,
    required this.indicatorComponentsStyles,
  });

  bool operator ==(other) {
    if (other is Indicator) {
      return other.name == this.name;
    } else {
      return false;
    }
  }
}

class IndicatorStyle {
  final String name;
  final Color color;

  IndicatorStyle({
    required this.name,
    required this.color,
  });
}
