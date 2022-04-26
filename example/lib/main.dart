import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Candle> candles = [];
  bool themeIsDark = false;
  List<Indicator> indicators = [
    Indicator(
      name: "BB 20",
      dependsOnNPrevCandles: 20,
      calculator: (index, candles) {
        double sum = 0;
        for (int i = index; i < index + 20; i++) {
          sum += candles[i].close;
        }
        final average = sum / 20;

        num sumOfSquaredDiffFromMean = 0;
        for (int i = index; i < index + 20; i++) {
          final squareDiffFromMean = math.pow(candles[i].close - average, 2);
          sumOfSquaredDiffFromMean += squareDiffFromMean;
        }

        final variance = sumOfSquaredDiffFromMean / 20;

        final standardDeviation = math.sqrt(variance);

        return [
          average + standardDeviation * 2,
          average,
          average - standardDeviation * 2
        ];
      },
      indicatorComponentsStyles: [
        IndicatorStyle(name: "high", color: Colors.blue.shade900),
        IndicatorStyle(name: "mid", color: Colors.yellow.shade800),
        IndicatorStyle(name: "low", color: Colors.pink.shade800)
      ],
    ),
    Indicator(
      name: "MA 100",
      dependsOnNPrevCandles: 100,
      calculator: (index, candles) {
        double sum = 0;
        for (int i = index; i < index + 100; i++) {
          sum += candles[i].close;
        }
        return [sum / 100];
      },
      indicatorComponentsStyles: [
        IndicatorStyle(name: "mv", color: Colors.green.shade600),
      ],
    ),
  ];

  @override
  void initState() {
    fetchCandles().then((value) {
      setState(() {
        candles = value;
      });
    });
    super.initState();
  }

  Future<List<Candle>> fetchCandles() async {
    final uri = Uri.parse(
        "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1h");
    final res = await http.get(uri);
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => Candle.fromJson(e))
        .toList()
        .reversed
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: themeIsDark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("BTCUSDT 1H Chart"),
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
          child: Candlesticks(
            candles: candles,
            indicators: indicators,
            onRemoveIndicator: (indicatorName) {
              setState(() {
                setState(() {
                  indicators = [...indicators];
                  indicators
                      .removeWhere((element) => element.name == indicatorName);
                });
              });
            },
          ),
        ),
      ),
    );
  }
}
