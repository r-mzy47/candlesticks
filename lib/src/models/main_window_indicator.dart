import 'package:candlesticks/src/models/indicator.dart';
import 'dart:math' as math;
import 'candle.dart';
import 'package:flutter/material.dart';

class IndicatorComponentData {
  final String name;
  final Color color;
  final List<double?> values = [];
  DateTime? lastUpdateCandleData;
  final Indicator parentIndicator;
  final int indexOfIndicatorComponent;
  IndicatorComponentData(this.parentIndicator, this.name, this.color)
      : indexOfIndicatorComponent = parentIndicator.indicatorComponentsStyle
            .indexWhere((element) => element.name == name);
  bool visible = true;
}

class MainWidnowDataContainer {
  List<IndicatorComponentData> indicatorComponentData = [];
  List<Indicator> indicators;
  List<double> highs = [];
  List<double> lows = [];
  List<String> unvisibleIndicators = [];

  void toggleIndicatorVisibility(String indicatorName) {
    if (unvisibleIndicators.contains(indicatorName)) {
      unvisibleIndicators.remove(indicatorName);
      indicatorComponentData.forEach((element) {
        if (element.parentIndicator.name == indicatorName) {
          element.visible = true;
        }
      });
    } else {
      unvisibleIndicators.add(indicatorName);
      indicatorComponentData.forEach((element) {
        if (element.parentIndicator.name == indicatorName) {
          element.visible = false;
        }
      });
    }
  }

  MainWidnowDataContainer(this.indicators, List<Candle> candles) {
    indicators.forEach((indicator) {
      indicator.indicatorComponentsStyle.forEach((indicatorComponent) {
        indicatorComponentData.add(IndicatorComponentData(
            indicator, indicatorComponent.name, indicatorComponent.color));
      });
    });

    candles.forEach((candle) {
      highs.add(candle.high);
      lows.add(candle.low);
    });

    indicators.forEach((indicator) {
      final List<IndicatorComponentData> containers = indicatorComponentData
          .where((element) => element.parentIndicator == indicator)
          .toList();
      containers.sort(
          (a, b) => a.indexOfIndicatorComponent - b.indexOfIndicatorComponent);

      for (int i = 0;
          i + indicator.dependsOnNPrevCandles < candles.length;
          i++) {
        double low = lows[i];
        double high = highs[i];

        final indicatorDatas = indicator.calculator(i, candles);

        for (int i = 0; i < indicatorDatas.length; i++) {
          containers[i].values.add(indicatorDatas[i]);
          if (indicatorDatas[i] != null) {
            low = math.min(low, indicatorDatas[i]!);
            high = math.max(high, indicatorDatas[i]!);
          }
        }
        lows[i] = low;
        highs[i] = high;
      }
    });
  }

  void tickUpdate(List<Candle> candles) {
    // indicators.forEach(
    //   (indicator) {
    //     int i = 0;
    //     while (candles[i].date != indicator.lastUpdateCandleData) {
    //       i++;
    //     }
    //     indicator.datas.removeAt(0);
    //     for (int j = i; j >= 0; j--) {
    //       indicator.datas.insert(0, indicator.config.calculator(j, candles));
    //     }
    //   },
    // );
  }
}
