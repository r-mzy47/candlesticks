import 'dart:convert';

import 'package:candlesticks/candlesticks.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

Future<List<Candle>> fetchCandles(
    {required String symbol, required String interval, int? endTime}) async {
  final uri = Uri.parse(
      "https://api.binance.com/api/v3/klines?symbol=$symbol&interval=$interval" +
          (endTime != null ? "&endTime=$endTime" : ""));
  final res = await http.get(uri);
  return (jsonDecode(res.body) as List<dynamic>)
      .map((e) => Candle.fromJson(e))
      .toList()
      .reversed
      .toList();
}

WebSocketChannel establishConnection(String interval) {
  final channel = WebSocketChannel.connect(
    Uri.parse('wss://stream.binance.com:9443/ws'),
  );
  channel.sink.add(
    jsonEncode(
      {
        "method": "SUBSCRIBE",
        "params": ["xrpusdt@kline_" + interval],
        "id": 1
      },
    ),
  );
  return channel;
}
