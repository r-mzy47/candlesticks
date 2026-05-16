import 'package:candlesticks/candlesticks.dart';

class CandleTickerModel {
  final int eventTime;
  final String symbol;
  final Candle candle;

  const CandleTickerModel({
    required this.eventTime,
    required this.symbol,
    required this.candle,
  });

  factory CandleTickerModel.fromJson(Map<String, dynamic> json) {
    final kline = json['k'] as Map<String, dynamic>;

    return CandleTickerModel(
      eventTime: json['E'] as int,
      symbol: json['s'] as String,
      candle: Candle(
        date: DateTime.fromMillisecondsSinceEpoch(kline['t'] as int),
        high: double.parse(kline['h'] as String),
        low: double.parse(kline['l'] as String),
        open: double.parse(kline['o'] as String),
        close: double.parse(kline['c'] as String),
        volume: double.parse(kline['v'] as String),
      ),
    );
  }
}
