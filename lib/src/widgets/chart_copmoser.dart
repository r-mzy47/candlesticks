import 'dart:math';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/main.dart';
import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/candle_sticks_chart.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:candlesticks/src/widgets/time_row.dart';
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
  int? hoveredCandleIndex;

  void onHoveredCandleIndexChange(int? index) {
    setState(() {
      hoveredCandleIndex = index;
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
            return TweenAnimationBuilder<double>(
              tween: Tween(end: viewPort.candleWidth),
              duration: const Duration(milliseconds: 120),
              builder: (context, animatedWidth, _) {
                final animatedViewport =
                    viewPort.copyWith(candleWidth: animatedWidth);

                final int candlesEndIndex = min(
                    chartsWidth ~/ animatedViewport.candleWidth +
                        animatedViewport.scrollIndex,
                    widget.candles.length - 1);

                if (candlesEndIndex == widget.candles.length - 1) {
                  Future(() {
                    widget.onReachEnd();
                  });
                }

                return Container(
                  color: CandleSticksStyleProvider.of(context).background,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          right: PRICE_BAR_WIDTH,
                        ), // padding rigth PRICE_BAR_WIDTH
                        child: TimeRow(
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
                                onHoveredCandleIndexChange:
                                    onHoveredCandleIndexChange,
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
