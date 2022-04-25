import 'dart:math';
import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/models/main_window_indicator.dart';
import 'package:candlesticks/src/widgets/mobile_chart.dart';
import 'package:candlesticks/src/widgets/desktop_chart.dart';
import 'package:candlesticks/src/widgets/toolbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// StatefulWidget that holds Chart's State (index of
/// current position and candles width).
class Candlesticks extends StatefulWidget {
  /// The arrangement of the array should be such that
  ///  the newest item is in position 0
  final List<Candle> candles;

  /// this callback calls when the last candle gets visible
  final Future<void> Function()? onLoadMoreCandles;

  /// list of buttons you what to add on top tool bar
  final List<ToolBarAction> actions;

  final List<Indicator>? indicators;

  final void Function(String)? onRemoveIndicator;

  Candlesticks({
    Key? key,
    required this.candles,
    this.onLoadMoreCandles,
    this.actions = const [],
    this.indicators,
    this.onRemoveIndicator,
  }) : super(key: key);

  @override
  _CandlesticksState createState() => _CandlesticksState();
}

class _CandlesticksState extends State<Candlesticks> {
  /// index of the newest candle to be displayed
  /// changes when user scrolls along the chart
  int index = -10;
  double lastX = 0;
  int lastIndex = -10;

  /// candleWidth controls the width of the single candles.
  ///  range: [2...10]
  double candleWidth = 6;

  /// true when widget.onLoadMoreCandles is fetching new candles.
  bool isCallingLoadMore = false;

  MainWidnowDataContainer? mainWidnowDataContainer;

  @override
  void didUpdateWidget(covariant Candlesticks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.candles.length == 0) {
      return;
    }
    if (mainWidnowDataContainer == null) {
      mainWidnowDataContainer =
          MainWidnowDataContainer(widget.indicators ?? [], widget.candles);
    } else {
      final currentIndicators = widget.indicators ?? [];
      final oldIndicators = oldWidget.indicators ?? [];
      if (currentIndicators.length == oldIndicators.length) {
        for (int i = 0; i < currentIndicators.length; i++) {
          if (currentIndicators[i] == oldIndicators[i]) {
            continue;
          } else {
            mainWidnowDataContainer = MainWidnowDataContainer(
                widget.indicators ?? [], widget.candles);
            return;
          }
        }
      } else {
        mainWidnowDataContainer =
            MainWidnowDataContainer(widget.indicators ?? [], widget.candles);
        return;
      }
      mainWidnowDataContainer!.tickUpdate(widget.candles);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ToolBar(
          onZoomInPressed: () {
            setState(() {
              candleWidth += 2;
              candleWidth = min(candleWidth, 16);
            });
          },
          onZoomOutPressed: () {
            setState(() {
              candleWidth -= 2;
              candleWidth = max(candleWidth, 4);
            });
          },
          children: widget.actions,
        ),
        if (widget.candles.length == 0 || mainWidnowDataContainer == null)
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
              duration: Duration(milliseconds: 120),
              builder: (_, double width, __) {
                if (kIsWeb ||
                    Platform.isMacOS ||
                    Platform.isWindows ||
                    Platform.isLinux) {
                  return DesktopChart(
                    onRemoveIndicator: widget.onRemoveIndicator,
                    mainWidnowDataContainer: mainWidnowDataContainer!,
                    onScaleUpdate: (double scale) {
                      scale = max(0.90, scale);
                      scale = min(1.1, scale);
                      setState(() {
                        candleWidth *= scale;
                        candleWidth = min(candleWidth, 16);
                        candleWidth = max(candleWidth, 4);
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
                      if (isCallingLoadMore == false &&
                          widget.onLoadMoreCandles != null) {
                        isCallingLoadMore = true;
                        widget.onLoadMoreCandles!().then((_) {
                          isCallingLoadMore = false;
                        });
                      }
                    },
                    candleWidth: width,
                    candles: widget.candles,
                    index: index,
                  );
                } else {
                  return MobileChart(
                    onRemoveIndicator: widget.onRemoveIndicator,
                    mainWidnowDataContainer: mainWidnowDataContainer!,
                    onScaleUpdate: (double scale) {
                      scale = max(0.90, scale);
                      scale = min(1.1, scale);
                      setState(() {
                        candleWidth *= scale;
                        candleWidth = min(candleWidth, 16);
                        candleWidth = max(candleWidth, 4);
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
                      if (isCallingLoadMore == false &&
                          widget.onLoadMoreCandles != null) {
                        isCallingLoadMore = true;
                        widget.onLoadMoreCandles!().then((_) {
                          isCallingLoadMore = false;
                        });
                      }
                    },
                    candleWidth: width,
                    candles: widget.candles,
                    index: index,
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}
