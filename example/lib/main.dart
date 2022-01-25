import 'dart:convert';

import 'package:example/candle_ticker_model.dart';
import 'package:example/repository.dart';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Candle> candles = [];
  WebSocketChannel? _channel;
  bool themeIsDark = false;
  String currentInterval = "1m";

  @override
  void initState() {
    binanceFetch(currentInterval);
    super.initState();
  }

  @override
  void dispose() {
    if (_channel != null) _channel!.sink.close();
    super.dispose();
  }

  Future<void> binanceFetch(String interval) async {
    // close current channel if exists
    if (_channel != null) _channel!.sink.close();
    // clear last candle list
    setState(() {
      candles = [];
      currentInterval = interval;
    });

    try {
      // load candles info
      final data = await fetchCandles(symbol: "XRPUSDT", interval: interval);
      // connect to binance stream
      _channel = establishConnection(currentInterval);
      // update candles
      setState(() {
        candles = data;
        currentInterval = interval;
      });
    } catch (e) {
      // handle error
      return;
    }
  }

  void updateCandlesFromSnapshot(AsyncSnapshot<Object?> snapshot) {
    if (candles.length == 0) return;
    if (snapshot.data != null) {
      final map = jsonDecode(snapshot.data as String) as Map<String, dynamic>;
      if (map.containsKey("k") == true) {
        final candleTicker = CandleTickerModel.fromJson(map);

        // cehck if incoming candle is an update on current last candle, or a new one
        if (candles[0].date == candleTicker.candle.date) {
          // update last candle
          candles[0] = candleTicker.candle;
        }
        // check if incoming new candle is next candle so the difrence
        // between times must be the same as last existing 2 candles
        else if (candleTicker.candle.date.difference(candles[0].date) ==
            candles[0].date.difference(candles[1].date)) {
          // add new candle to list
          candles.insert(0, candleTicker.candle);
        }
      }
    }
  }

  Future<void> loadMoreCandles() async {
    try {
      // load candles info
      final data = await fetchCandles(
          symbol: "XRPUSDT",
          interval: currentInterval,
          endTime: candles.last.date.millisecondsSinceEpoch);
      candles.removeLast();
      setState(() {
        candles.addAll(data);
      });
    } catch (e) {
      // handle error
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: themeIsDark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("candleSticks"),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  themeIsDark = !themeIsDark;
                });
              },
              icon: Icon(
                themeIsDark
                    ? Icons.wb_sunny_sharp
                    : Icons.nightlight_round_outlined,
              ),
            )
          ],
        ),
        body: Center(
          child: StreamBuilder(
            stream: _channel == null ? null : _channel!.stream,
            builder: (context, snapshot) {
              updateCandlesFromSnapshot(snapshot);
              return Candlesticks(
                onIntervalChange: (String value) async {
                  binanceFetch(value);
                },
                candles: candles,
                interval: currentInterval,
                onLoadMoreCandles: loadMoreCandles,
              );
            },
          ),
        ),
      ),
    );
  }
}
