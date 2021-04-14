class Candle {
  final double high;
  final double low;
  final double open;
  final double close;
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
