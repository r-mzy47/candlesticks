import 'dart:math';

import 'package:candlesticks/src/constant/view_constants.dart';

class HelperFunctions {
  static double log10(num x) => log(x) / ln10;

  static double getRoof(double number) {
    if (number == 0) {
      return 1;
    }
    int log = log10(number).floor();
    return (number ~/ pow(10, log) + 1) * pow(10, log).toDouble();
  }

  static String addMetricPrefix(double price) {
    if (price < 1) price = 1;
    int log = log10(price).floor();
    if (log > 9) {
      return '${price ~/ 1000000000}B';
    } else if (log > 6) {
      return '${price ~/ 1000000}M';
    } else if (log > 3) {
      return '${price ~/ 1000}K';
    } else {
      return price.toStringAsFixed(0);
    }
  }

  static String priceToString(double price) {
    final absPrice = price.abs();

    if (absPrice > 100000) return price.toStringAsFixed(0);
    if (absPrice > 10000) return price.toStringAsFixed(1);
    if (absPrice > 1000) return price.toStringAsFixed(2);
    if (absPrice > 100) return price.toStringAsFixed(3);
    if (absPrice > 10) return price.toStringAsFixed(4);
    if (absPrice > 1) return price.toStringAsFixed(5);

    return price.toStringAsFixed(7);
  }

  static double calculatePriceScale(double height, double high, double low) {
    int minTiles = (height / MIN_PRICETILE_HEIGHT).floor();
    minTiles = max(2, minTiles);
    double sizeRange = high - low;
    assert(
      sizeRange != 0,
      'highest highs and lowest lows of visible candles are equal.',
    );
    double minStepSize = sizeRange / minTiles;
    double base =
        pow(10, HelperFunctions.log10(minStepSize).floor()).toDouble();

    if (2 * base > minStepSize) return 2 * base;
    if (5 * base > minStepSize) return 5 * base;
    return 10 * base;
  }
}
