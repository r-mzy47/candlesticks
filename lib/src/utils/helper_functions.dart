import 'dart:math';

class HelperFunctions {
  static double log10(num x) => log(x) / ln10;

  static double getRoof(double number) {
    int log = log10(number).floor();
    return (number ~/ pow(10, log) + 1) * pow(10, log).toDouble();
  }

  static String addMetricPrefix(double price) {
    if (price < 1) price = 1;
    int log = log10(price).floor();
    if (log > 9)
      return "${price ~/ 1000000000}B";
    else if (log > 6)
      return "${price ~/ 1000000}M";
    else if (log > 3)
      return "${price ~/ 1000}K";
    else
      return "${price.toStringAsFixed(0)}";
  }

  static String priceToString(double price) {
    return price > 1000
        ? price.toStringAsFixed(2)
        : price > 100
            ? price.toStringAsFixed(3)
            : price > 10
                ? price.toStringAsFixed(4)
                : price > 1
                    ? price.toStringAsFixed(5)
                    : price.toStringAsFixed(7);
  }
}
