import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';

class Indicator {
  final String name;
  final List<double?> Function(int index, List<Candle> candles) calculator;
  final int dependsOnNPrevCandles;
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
