import 'dart:convert';

import 'package:candlesticks/candlesticks.dart';
import 'package:example/symbol_search_modal.dart';
import 'package:example/toolbar.dart';
import 'package:example/toolbar_action.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import './candle_ticker_model.dart';
import './repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _defaultSymbol = 'BTCUSDT';
  static const String _defaultInterval = '4h';

  final BinanceRepository _repository = BinanceRepository();
  final CandlesticksController _controller = CandlesticksController();

  final List<String> _intervals = const [
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

  WebSocketChannel? _channel;

  List<Candle> _candles = [];
  List<String> _symbols = [];

  bool _themeIsDark = false;
  String _currentSymbol = '';
  String _currentInterval = _defaultInterval;

  @override
  void initState() {
    super.initState();
    _loadSymbols();
  }

  @override
  void dispose() {
    _closeChannel();
    super.dispose();
  }

  Future<void> _loadSymbols() async {
    try {
      final symbols = await _repository.fetchSymbols();

      if (!mounted) return;

      setState(() {
        _symbols = symbols;
      });

      if (symbols.isNotEmpty) {
        await _loadCandles(_defaultSymbol, _currentInterval);
      }
    } catch (_) {
      // You can show an error message here if needed.
    }
  }

  Future<void> _loadCandles(String symbol, String interval) async {
    _closeChannel();

    setState(() {
      _candles = [];
      _currentInterval = interval;
    });

    try {
      final candles = await _repository.fetchCandles(
        symbol: symbol,
        interval: interval,
      );

      final channel = _repository.establishConnection(
        symbol.toLowerCase(),
        interval,
      );

      if (!mounted) {
        channel.sink.close();
        return;
      }

      setState(() {
        _candles = candles;
        _channel = channel;
        _currentSymbol = symbol;
        _currentInterval = interval;
      });
    } catch (_) {
      // You can show an error message here if needed.
    }
  }

  Future<void> _loadMoreCandles() async {
    if (_candles.isEmpty || _currentSymbol.isEmpty) return;

    try {
      final candles = await _repository.fetchCandles(
        symbol: _currentSymbol,
        interval: _currentInterval,
        endTime: _candles.last.date.millisecondsSinceEpoch,
      );

      if (!mounted) return;

      setState(() {
        if (_candles.isNotEmpty) {
          _candles.removeLast();
        }

        _candles.addAll(candles);
      });
    } catch (_) {
      // You can show an error message here if needed.
    }
  }

  void _closeChannel() {
    _channel?.sink.close();
    _channel = null;
  }

  void _toggleTheme() {
    setState(() {
      _themeIsDark = !_themeIsDark;
    });
  }

  void _handleSocketSnapshot(AsyncSnapshot<Object?> snapshot) {
    final data = snapshot.data;

    if (_candles.isEmpty || data == null || data is! String) return;

    final candle = _parseCandleFromSocketData(data);
    if (candle == null) return;

    setState(() {
      _upsertLiveCandle(candle);
    });
  }

  Candle? _parseCandleFromSocketData(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;

      if (!json.containsKey('k')) return null;

      return CandleTickerModel.fromJson(json).candle;
    } catch (_) {
      return null;
    }
  }

  void _upsertLiveCandle(Candle candle) {
    if (_candles.isEmpty) return;

    final latestCandle = _candles.first;

    final isLatestCandleUpdate =
        latestCandle.date == candle.date && latestCandle.open == candle.open;

    if (isLatestCandleUpdate) {
      _candles[0] = candle;
      return;
    }

    if (_candles.length < 2) {
      _candles.insert(0, candle);
      return;
    }

    final latestInterval = _candles[0].date.difference(_candles[1].date);
    final incomingInterval = candle.date.difference(_candles[0].date);

    if (incomingInterval == latestInterval) {
      _candles.insert(0, candle);
    }
  }

  void _showIntervalDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Center(
          child: Material(
            child: Container(
              width: 200,
              color: Theme.of(context).colorScheme.surface,
              child: Wrap(
                children: _intervals.map(_buildIntervalButton).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntervalButton(String interval) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 50,
        height: 30,
        child: RawMaterialButton(
          elevation: 0,
          fillColor: const Color(0xFF494537),
          onPressed: () {
            if (_currentSymbol.isNotEmpty) {
              _loadCandles(_currentSymbol, interval);
            }

            Navigator.of(context).pop();
          },
          child: Text(
            interval,
            style: const TextStyle(
              color: Color(0xFFF0B90A),
            ),
          ),
        ),
      ),
    );
  }

  void _showSymbolSearchDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return SymbolsSearchModal(
          symbols: _symbols,
          onSelect: (symbol) {
            _loadCandles(symbol, _currentInterval);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _themeIsDark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: StreamBuilder<Object?>(
          stream: _channel?.stream,
          builder: (context, snapshot) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _handleSocketSnapshot(snapshot);
              }
            });

            return Column(
              children: [
                ToolBar(
                  leftChildren: [
                    ToolBarAction(
                      onPressed: _controller.zoomOut,
                      child: const Icon(Icons.remove),
                    ),
                    ToolBarAction(
                      onPressed: _controller.zoomIn,
                      child: const Icon(Icons.add),
                    ),
                    ToolBarAction(
                      onPressed: () => _showIntervalDialog(context),
                      child: Text(_currentInterval),
                    ),
                    ToolBarAction(
                      width: 100,
                      onPressed: () => _showSymbolSearchDialog(context),
                      child: Text(_currentSymbol),
                    ),
                  ],
                  rightChildren: [
                    ToolBarAction(
                      width: 50,
                      onPressed: _toggleTheme,
                      child: Icon(
                        _themeIsDark
                            ? Icons.wb_sunny_sharp
                            : Icons.nightlight_round_outlined,
                      ),
                    )
                  ],
                ),
                Expanded(
                  child: Candlesticks(
                    key: Key('$_currentSymbol-$_currentInterval'),
                    candles: _candles,
                    onLoadMoreCandles: _loadMoreCandles,
                    controller: _controller,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
