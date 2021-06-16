import 'dart:convert';

import 'package:example/repository.dart';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'candleSticks',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Candle> candles = [];
  final _channel = WebSocketChannel.connect(
    Uri.parse('wss://stream.binance.com:9443/ws'),
  );

  @override
  void initState() {
    fetchCandles(symbol: "BTCUSDT", interval: "1h").then((value) {
      setState(() {
        candles = value;
      });
      print(value[0].date.day);
    });
    _channel.sink.add(
      jsonEncode(
        {
          "method": "SUBSCRIBE",
          "params": ["btcusdt@kline_1h"],
          "id": 1
        },
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("candleSticks"),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 1.2,
          child: StreamBuilder(
            stream: _channel.stream,
            builder: (context, snapshot) {
              if (snapshot.data != null) {
                final data = jsonDecode(snapshot.data as String) as Map<String, dynamic>;
                if (data.containsKey("k") == true && candles[0].date.millisecondsSinceEpoch == data["k"]["t"]) {
                  candles[0] = Candle(
                      date: candles[0].date,
                      high: double.parse(data["k"]["h"]),
                      low: double.parse(data["k"]["l"]),
                      open: double.parse(data["k"]["o"]),
                      close: double.parse(data["k"]["c"]),
                      volume: double.parse(data["k"]["v"]));
                }
                else if (data.containsKey("k") == true) {
                  candles.insert(0, Candle(
                      date: DateTime.fromMillisecondsSinceEpoch(data["k"]["t"]),
                      high: double.parse(data["k"]["h"]),
                      low: double.parse(data["k"]["l"]),
                      open: double.parse(data["k"]["o"]),
                      close: double.parse(data["k"]["c"]),
                      volume: double.parse(data["k"]["v"])));
                }
              }
              // candles[0] = new Candle(close: )
              return Candlesticks(
                candles: candles,
              );
            },
          ),
        ),
      ),
    );
  }
}
