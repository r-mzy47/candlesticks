import 'dart:math';
import 'package:candlesticks/src/constant/intervals.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/theme/theme_data.dart';
import 'package:candlesticks/src/widgets/mobile_chart.dart';
import 'package:candlesticks/src/widgets/web_chart.dart';
import 'package:candlesticks/src/widgets/toolbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'models/candle.dart';

/// StatefulWidget that holds Chart's State (index of
/// current position and candles width).
class Candlesticks extends StatefulWidget {
  final List<Candle> candles;

  /// callback calls wshen user changes interval
  final Future<void> Function(String) onIntervalChange;

  final String interval;

  final List<String>? intervals;

  final Future<void> Function()? onLoadMoreCandles;

  Candlesticks({
    required this.candles,
    required this.onIntervalChange,
    required this.interval,
    this.onLoadMoreCandles,
    this.intervals,
  });

  @override
  _CandlesticksState createState() => _CandlesticksState();
}

/// [Candlesticks] state
class _CandlesticksState extends State<Candlesticks> {
  /// index of the newest candle to be displayed
  /// changes when user scrolls along the chart
  int index = -10;

  double lastX = 0;
  int lastIndex = -10;

  @override
  void didUpdateWidget(Candlesticks oldWidget) {
    if (oldWidget.interval != widget.interval) {
      index = -10;
      lastX = 0;
      lastIndex = -10;
    }
    super.didUpdateWidget(oldWidget);
  }

  /// candleWidth controls the width of the single candles.
  ///  range: [2...10]
  double candleWidth = 6;

  bool showIntervals = false;

  bool isCallingLoadMore = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ToolBar(
          onZoomInPressed: () {
            setState(() {
              candleWidth += 2;
              candleWidth = min(candleWidth, 10);
            });
          },
          onZoomOutPressed: () {
            setState(() {
              candleWidth -= 2;
              candleWidth = max(candleWidth, 2);
            });
          },
          interval: widget.interval,
          intervals: widget.intervals ?? intervals,
          onIntervalChange: widget.onIntervalChange,
        ),
        if (widget.candles.length == 0)
          Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).gold,
              ),
            ),
          )
        else
          Expanded(
            child: TweenAnimationBuilder(
              tween: Tween(begin: 6.toDouble(), end: candleWidth),
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOutCirc,
              builder: (_, width, __) {
                return kIsWeb
                    ? WebChart(
                        onScaleUpdate: (double scale) {
                          scale = max(0.95, scale);
                          scale = min(1.05, scale);
                          setState(() {
                            candleWidth *= scale;
                            candleWidth = min(candleWidth, 10);
                            candleWidth = max(candleWidth, 2);
                            candleWidth.toInt();
                          });
                        },
                        onPanEnd: () {
                          lastIndex = index;
                        },
                        onHorizontalDragUpdate: (double x) {
                          setState(() {
                            x = x - lastX;
                            index = lastIndex + x ~/ candleWidth;
                            index = max(index, -10);
                            index = min(index, widget.candles.length - 1);
                          });
                        },
                        onPanDown: (double value) {
                          lastX = value;
                          lastIndex = index;
                        },
                        onReachEnd: () {
                          if (isCallingLoadMore == false) {
                            isCallingLoadMore = true;
                            widget.onLoadMoreCandles!().then((_) {
                              isCallingLoadMore = false;
                            });
                          }
                        },
                        candleWidth: width as double,
                        candles: widget.candles,
                        index: index,
                      )
                    : MobileChart(
                        onScaleUpdate: (double scale) {
                          scale = max(0.95, scale);
                          scale = min(1.05, scale);
                          setState(() {
                            candleWidth *= scale;
                            candleWidth = min(candleWidth, 10);
                            candleWidth = max(candleWidth, 2);
                            candleWidth.toInt();
                          });
                        },
                        onPanEnd: () {
                          lastIndex = index;
                        },
                        onHorizontalDragUpdate: (double x) {
                          setState(() {
                            x = x - lastX;
                            index = lastIndex + x ~/ candleWidth;
                            index = max(index, -10);
                            index = min(index, widget.candles.length - 1);
                          });
                        },
                        onPanDown: (double value) {
                          lastX = value;
                          lastIndex = index;
                        },
                        onReachEnd: () {
                          if (isCallingLoadMore == false) {
                            isCallingLoadMore = true;
                            widget.onLoadMoreCandles!().then((_) {
                              isCallingLoadMore = false;
                            });
                          }
                        },
                        candleWidth: width as double,
                        candles: widget.candles,
                        index: index,
                      );
              },
            ),
          ),
      ],
    );
  }
}
