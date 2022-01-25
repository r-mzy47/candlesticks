import 'package:candlesticks/candlesticks.dart';

class CandleTickerModel {
  final int eventTime;
  final String symbol;
  final Candle candle;

  const CandleTickerModel(
      {required this.eventTime, required this.symbol, required this.candle});

  factory CandleTickerModel.fromJson(Map<String, dynamic> json) {
    return CandleTickerModel(
        eventTime: json['E'] as int,
        symbol: json['s'] as String,
        candle: Candle(
            date: DateTime.fromMillisecondsSinceEpoch(json["k"]["t"]),
            high: double.parse(json["k"]["h"]),
            low: double.parse(json["k"]["l"]),
            open: double.parse(json["k"]["o"]),
            close: double.parse(json["k"]["c"]),
            volume: double.parse(json["k"]["v"])));
  }
}
