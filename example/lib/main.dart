import 'package:example/repository.dart';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';

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

  @override
  void initState() {
    fetchCandles(symbol: "BTCUSDT", interval: "1h").then((value) {
      setState(() {
        candles = value;
      });
    });
    super.initState();
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
          child: Candlesticks(
            candles: candles,
          ),
        ),
      ),
    );
  }
}
