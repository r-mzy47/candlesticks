import 'dart:convert';
import './candle_ticker_model.dart';
import './repository.dart';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:math' as math;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BinanceRepository repository = new BinanceRepository();

  List<Candle> candles = [];
  WebSocketChannel? _channel;
  bool themeIsDark = false;
  String currentInterval = "1m";
  final intervals = [
    '1m',
    '3m',
    '5m',
    '15m',
    '30m',
    '1h',
    '2h',
    '4h',
    '6h',
    '8h',
    '12h',
    '1d',
    '3d',
    '1w',
    '1M',
  ];
  List<String> symbols = [];
  String currentSymbol = "";
  List<Indicator> indicators = [];

  @override
  void initState() {
    fetchSymbols().then((value) {
      symbols = value;
      if (symbols.length != 0) fetchCandles(symbols[0], currentInterval);
    });
    indicators = [
      Indicator(
        name: "BB 3",
        dependsOnNPrevCandles: 3,
        calculator: (index, candles) {
          double sum = 0;
          for (int i = index; i < index + 3; i++) {
            sum += candles[i].close;
          }
          final average = sum / 3;

          num sumOfSquaredDiffFromMean = 0;
          for (int i = index; i < index + 3; i++) {
            final squareDiffFromMean = math.pow(candles[i].close - average, 2);
            sumOfSquaredDiffFromMean += squareDiffFromMean;
          }

          final variance = sumOfSquaredDiffFromMean / 3;

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
        dependsOnNPrevCandles: 1,
        calculator: (index, candles) {
          double sum = 0;
          for (int i = index; i < index + 1; i++) {
            sum += candles[i].close;
          }
          return [sum / 1];
        },
        indicatorComponentsStyles: [
          IndicatorStyle(name: "mv", color: Colors.green.shade600),
        ],
      ),
    ];
    super.initState();
  }

  @override
  void dispose() {
    if (_channel != null) _channel!.sink.close();
    super.dispose();
  }

  Future<List<String>> fetchSymbols() async {
    try {
      // load candles info
      final data = await repository.fetchSymbols();
      return data;
    } catch (e) {
      // handle error
      return [];
    }
  }

  Future<void> fetchCandles(String symbol, String interval) async {
    // close current channel if exists
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    // clear last candle list
    setState(() {
      candles = [];
      currentInterval = interval;
    });

    try {
      // load candles info
      final data =
          await repository.fetchCandles(symbol: symbol, interval: interval);
      // connect to binance stream
      _channel =
          repository.establishConnection(symbol.toLowerCase(), currentInterval);
      // update candles
      setState(() {
        candles = data;
        currentInterval = interval;
        currentSymbol = symbol;
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
        if (candles[0].date == candleTicker.candle.date &&
            candles[0].open == candleTicker.candle.open) {
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
      final data = await repository.fetchCandles(
          symbol: currentSymbol,
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
          title: Text("Binance Candles"),
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
                key: Key(currentSymbol + currentInterval),
                indicators: indicators,
                candles: candles,
                onLoadMoreCandles: loadMoreCandles,
                onRemoveIndicator: (String indicator) {
                  setState(() {
                    indicators
                        .removeWhere((element) => element.name == indicator);
                  });
                },
                actions: [
                  ToolBarAction(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Center(
                            child: Container(
                              width: 200,
                              color: Theme.of(context).digalogColor,
                              child: Wrap(
                                children: intervals
                                    .map((e) => Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: SizedBox(
                                            width: 50,
                                            height: 30,
                                            child: RawMaterialButton(
                                              elevation: 0,
                                              fillColor:
                                                  Theme.of(context).lightGold,
                                              onPressed: () {
                                                fetchCandles(currentSymbol, e);
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                e,
                                                style: TextStyle(
                                                  color: Theme.of(context).gold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Text(
                      currentInterval,
                      style: TextStyle(
                        color: Theme.of(context).grayColor,
                      ),
                    ),
                  ),
                  ToolBarAction(
                    width: 100,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return SymbolSearchModal(
                            symbols: symbols,
                            onSelect: (value) {
                              fetchCandles(value, currentInterval);
                            },
                          );
                        },
                      );
                    },
                    child: Text(
                      currentSymbol,
                      style: TextStyle(
                        color: Theme.of(context).grayColor,
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class SymbolSearchModal extends StatefulWidget {
  const SymbolSearchModal({
    Key? key,
    required this.onSelect,
    required this.symbols,
  }) : super(key: key);

  final Function(String symbol) onSelect;
  final List<String> symbols;

  @override
  State<SymbolSearchModal> createState() => _SymbolSearchModalState();
}

class _SymbolSearchModalState extends State<SymbolSearchModal> {
  String symbolSearch = "";
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        child: Container(
          width: 300,
          height: MediaQuery.of(context).size.height * 0.75,
          color: Theme.of(context).digalogColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(prefixIcon: Icon(Icons.search)),
                  onChanged: (value) {
                    setState(() {
                      symbolSearch = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  children: widget.symbols
                      .where((element) => element
                          .toLowerCase()
                          .contains(symbolSearch.toLowerCase()))
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 50,
                              height: 30,
                              child: RawMaterialButton(
                                elevation: 0,
                                fillColor: Theme.of(context).lightGold,
                                onPressed: () {
                                  widget.onSelect(e);
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  e,
                                  style: TextStyle(
                                    color: Theme.of(context).gold,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
