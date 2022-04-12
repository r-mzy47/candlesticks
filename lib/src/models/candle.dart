import 'dart:math';

/// Candle model which holds a single candle data.
/// It contains five required double variables that hold a single candle data: high, low, open, close and volume.
/// It can be instantiated using its default constructor or fromJson named constructor.
class Candle {
  /// DateTime for the candle
  final DateTime date;

  /// The height price during this candle lifetime
  /// It if always more than low, open and close
  final double high;

  /// The lowest price during this candle lifetime
  /// It if always less than high, open and close
  final double low;

  /// Price at the beginning of the period
  final double open;

  /// Price at the end of the period
  final double close;

  /// Volume is the number of shares of a
  /// security traded during a given period of time.
  final double volume;

  double? ma7, ma25, ma99;

  double? get maxMa => ma7 != null && ma25 != null && ma99 != null ? max(max(ma7 ?? 0, ma25 ?? 0), ma99 ?? 0) : null;

  double? get minMa => ma7 != null && ma25 != null && ma99 != null ? min(min(ma7 ?? 0, ma25 ?? 0), ma99 ?? 0) : null;

  bool get isBull => open <= close;

  Candle({
    required this.date,
    required this.high,
    required this.low,
    required this.open,
    required this.close,
    required this.volume,
  });

  Candle.fromJson(List<dynamic> json)
      : date = DateTime.fromMillisecondsSinceEpoch(json[0]),
        high = double.parse(json[2]),
        low = double.parse(json[3]),
        open = double.parse(json[1]),
        close = double.parse(json[4]),
        volume = double.parse(json[5]);
}
