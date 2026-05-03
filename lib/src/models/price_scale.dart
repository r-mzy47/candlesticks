import 'dart:math';

abstract class PriceScale {
  const PriceScale();

  double transform(double price);

  double inverse(double value);

  bool isValid(double price);

  ({double low, double high}) addPadding({
    required double low,
    required double high,
    double topPaddingFactor = 0.1,
    double bottomPaddingFactor = 0.2,
  }) {
    if (high <= low || !isValid(low) || !isValid(high)) {
      return (low: low, high: high);
    }

    final transformedLow = transform(low);
    final transformedHigh = transform(high);

    final diff = transformedHigh - transformedLow;

    final paddedLow = transformedLow - diff * bottomPaddingFactor;
    final paddedHigh = transformedHigh + diff * topPaddingFactor;

    return (
      low: inverse(paddedLow),
      high: inverse(paddedHigh),
    );
  }
}

class LinearPriceScale extends PriceScale {
  const LinearPriceScale();

  @override
  double transform(double price) => price;

  @override
  double inverse(double value) => value;

  @override
  bool isValid(double price) => true;
}

class LogPriceScale extends PriceScale {
  const LogPriceScale();

  @override
  double transform(double price) => log(price);

  @override
  double inverse(double value) => exp(value);

  @override
  bool isValid(double price) => price > 0;
}

class Log10PriceScale extends PriceScale {
  const Log10PriceScale();

  @override
  double transform(double price) => log(price) / ln10;

  @override
  double inverse(double value) => pow(10, value).toDouble();

  @override
  bool isValid(double price) => price > 0;
}

const PriceScale linearPriceScale = LinearPriceScale();
const PriceScale logPriceScale = LogPriceScale();
const PriceScale log10PriceScale = Log10PriceScale();
