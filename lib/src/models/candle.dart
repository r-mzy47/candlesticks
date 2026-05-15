/// Candle model wich holds a single candle data.
/// It contains five required double variables that hold a single candle data: high, low, open, close and volume.
/// It can be instantiated using its default constructor or fromJson named custructor.
class Candle {
  /// DateTime for the candle
  final DateTime date;

  /// The highest price during this candle lifetime
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

  bool get isBull => open <= close;

  const Candle({
    required this.date,
    required this.high,
    required this.low,
    required this.open,
    required this.close,
    required this.volume,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch,
      'high': high,
      'low': low,
      'open': open,
      'close': close,
      'volume': volume,
    };
  }

  factory Candle.fromJson(Map<String, dynamic> json) {
    return Candle(
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      open: (json['open'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
    );
  }
}
