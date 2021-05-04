/// Candle model wich holds a single candle data.
/// It contains five required double variables that hold a single candle data: high, low, open, close and volume.
/// It can be instantiated using its default constructor or fromJson named custructor.
class Candle {
  /// The highet price during this candle lifetime
  /// It if always more than low, open and close
  final double high;
  /// The lowest price during this candle lifetime
  /// It if always less than high, open and close
  final double low;
  /// Price at the beginnig of the period
  final double open;
  /// Price at the end of the period
  final double close;
  /// Volume is the number of shares of a 
  /// security traded during a given period of time.
  final double volume;

  Candle({
    required this.high,
    required this.low,
    required this.open,
    required this.close,
    required this.volume,
  });

  Candle.fromJson(Map<String, dynamic> json)
      : high = json['high'],
        low = json['low'],
        open = json['open'],
        close = json['close'],
        volume = json['volume'];
}
