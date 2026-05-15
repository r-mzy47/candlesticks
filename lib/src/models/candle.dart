/// A single OHLCV candle used by the candlestick chart.
///
/// A [Candle] represents one time period in a financial chart. It contains
/// the candle timestamp, open price, high price, low price, close price, and
/// traded volume.
///
/// The [date] should represent the opening time of the candle period.
///
/// Example:
///
/// ```dart
/// final candle = Candle(
///   date: DateTime.now(),
///   open: 1780.36,
///   high: 1873.93,
///   low: 1755.34,
///   close: 1848.56,
///   volume: 1200,
/// );
/// ```
class Candle {
  /// The timestamp of this candle.
  ///
  /// This usually represents the opening time of the candle interval.
  final DateTime date;

  /// The highest traded price during this candle period.
  ///
  /// This value is usually greater than or equal to [open], [close], and [low].
  final double high;

  /// The lowest traded price during this candle period.
  ///
  /// This value is usually less than or equal to [open], [close], and [high].
  final double low;

  /// The price at the beginning of this candle period.
  final double open;

  /// The price at the end of this candle period.
  final double close;

  /// The traded volume during this candle period.
  final double volume;

  /// Whether this candle closed at or above its opening price.
  ///
  /// A bullish candle is usually drawn with the chart's bull colors.
  bool get isBull => open <= close;

  /// Creates a candle from OHLCV data.
  const Candle({
    required this.date,
    required this.high,
    required this.low,
    required this.open,
    required this.close,
    required this.volume,
  });

  /// Converts this candle to a JSON-compatible map.
  ///
  /// The [date] is stored as milliseconds since the Unix epoch.
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

  /// Creates a candle from a JSON map.
  ///
  /// The expected format is:
  ///
  /// ```json
  /// {
  ///   "date": 1715731200000,
  ///   "high": 1873.93,
  ///   "low": 1755.34,
  ///   "open": 1780.36,
  ///   "close": 1848.56,
  ///   "volume": 1200
  /// }
  /// ```
  ///
  /// The [date] value must be milliseconds since the Unix epoch.
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
