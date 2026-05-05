import 'dart:math';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport_tween.dart';
import 'package:candlesticks/src/main.dart';
import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/widgets/axis/time_axis.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/candle_sticks_chart.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:flutter/material.dart';
import '../models/candle.dart';

/// This widget manages gestures
/// Calculates the highest and lowest price of visible candles.
/// Updates right-hand side numbers.
/// And pass values down to [CandleStickWidget].
class ChartComposer extends StatefulWidget {
  /// list of all candles to display in chart
  final List<Candle> candles;

  /// Will chart resize vertically by visible range
  /// or by the whole dataset
  final ChartAdjust chartAdjust;

  final Function() onReachEnd;

  final CandlesticksController controller;

  ChartComposer({
    required this.candles,
    required this.chartAdjust,
    required this.onReachEnd,
    required this.controller,
  });

  @override
  State<ChartComposer> createState() => _ChartComposerState();
}

class _ChartComposerState extends State<ChartComposer> {
  double? mouseHoverX;

  void onMouseHoverXChange(double? value) {
    setState(() {
      mouseHoverX = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // determine chart width
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        final double chartsWidth = maxWidth - PRICE_BAR_WIDTH;

        return ValueListenableBuilder(
          valueListenable: widget.controller,
          builder: (context, viewPort, child) {
            return TweenAnimationBuilder<CandlesticksViewport>(
              tween: CandlesticksViewportTween(
                end: viewPort,
              ),
              duration: Duration(
                milliseconds: max(
                  120,
                  viewPort.scrollIndexAnimationDurationMs,
                ),
              ),
              curve: Curves.linear,
              builder: (context, animatedViewport, _) {
                final int candlesStartIndex =
                    animatedViewport.firstVisibleCandleIndex;

                final int candlesEndIndex = min(
                  candlesStartIndex +
                      chartsWidth ~/ animatedViewport.candleWidth,
                  widget.candles.length - 1,
                );

                if (candlesEndIndex == widget.candles.length - 1) {
                  Future(() {
                    widget.onReachEnd();
                  });
                }

                int? hoveredCandleIndex;

                if (mouseHoverX != null) {
                  hoveredCandleIndex =
                      (((maxWidth - PRICE_BAR_WIDTH) - mouseHoverX!) /
                                  animatedViewport.candleWidth +
                              animatedViewport.scrollIndex)
                          .floor();

                  hoveredCandleIndex = hoveredCandleIndex.clamp(
                    0,
                    widget.candles.length - 1,
                  );
                }

                return Container(
                  color: CandleSticksStyleProvider.of(context).background,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          right: PRICE_BAR_WIDTH,
                        ), // padding rigth PRICE_BAR_WIDTH
                        child: TimeAxis(
                          hoverdCandleIndex: hoveredCandleIndex,
                          candles: widget.candles,
                          viewport: animatedViewport,
                          maxHeight: maxHeight,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: DATE_BAR_HEIGHT,
                        ), // padding rigth PRICE_BAR_WIDTH
                        child: Column(
                          children: [
                            Expanded(
                              child: CandleSticksChart(
                                candles: widget.candles,
                                chartAdjust: widget.chartAdjust,
                                controller: widget.controller,
                                viewPort: animatedViewport,
                                onMouseHoverXChange: onMouseHoverXChange,
                                hoveredCandleIndex: hoveredCandleIndex,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
