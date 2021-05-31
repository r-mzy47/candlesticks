import 'dart:convert';

import 'package:candlesticks/candlesticks.dart';
import 'package:http/http.dart' as http;

Future<List<Candle>> fetchCandles(
    {required String symbol, required String interval}) async {
  final uri = Uri.parse(
      "https://api.binance.com/api/v3/klines?symbol=$symbol&interval=$interval&limit=1000");
  final res = await http.get(uri);
  return (jsonDecode(res.body) as List<dynamic>)
      .map((e) => Candle.fromJson(e))
      .toList()
      .reversed
      .toList();
}
