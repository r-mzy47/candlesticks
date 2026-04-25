import 'dart:math';

import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/main.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/gesture_handler.dart';
import 'package:candlesticks/src/widgets/high_low_animator.dart';
import 'package:candlesticks/src/widgets/price_column.dart';
import 'package:candlesticks/src/widgets/top_panel.dart';
import 'package:candlesticks/src/widgets/volume_widget.dart';
import 'package:flutter/material.dart';

import '../models/candle.dart';

class CandleSticksChart extends StatelessWidget {
  const CandleSticksChart({
    super.key,
    required this.candles,
    required this.chartAdjust,
    required this.style,
    required this.controller,
    required this.viewPort,
    required this.onHoveredCandleIndexChange,
    this.hoveredCandleIndex,
  });

  final List<Candle> candles;

  final ChartAdjust chartAdjust;

  final CandleSticksStyle style;

  final CandlesticksController controller;

  final CandlesticksViewport viewPort;

  final Function(int?) onHoveredCandleIndexChange;

  final int? hoveredCandleIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;

        final double volumeBarsHeight = maxHeight * 0.2;

        final int candlesStartIndex = max(viewPort.scrollIndex, 0);
        final int candlesEndIndex = min(
          maxWidth ~/ viewPort.candleWidth + viewPort.scrollIndex,
          candles.length - 1,
        );
        List<Candle> inRangeCandles =
            candles.getRange(candlesStartIndex, candlesEndIndex + 1).toList();

        double candlesHighPrice = 0;
        double candlesLowPrice = 0;

        if (chartAdjust == ChartAdjust.visibleRange) {
          candlesHighPrice = inRangeCandles.map((c) => c.high).reduce(max);
          candlesLowPrice = inRangeCandles.map((c) => c.low).reduce(min);
          double diff = candlesHighPrice - candlesLowPrice;
          candlesHighPrice += diff * 0.1;
          candlesLowPrice -= diff * 0.2;
        } else if (chartAdjust == ChartAdjust.fullRange) {
          candlesHighPrice = candles.map((c) => c.high).reduce(max);
          candlesLowPrice = candles.map((c) => c.low).reduce(min);
          double diff = candlesHighPrice - candlesLowPrice;
          candlesHighPrice += diff * 0.1;
          candlesLowPrice -= diff * 0.2;
        }

        if (candlesHighPrice == candlesLowPrice) {
          candlesHighPrice += 10;
          candlesLowPrice -= 10;
        }

        // calculate highest volume
        double volumeHigh = inRangeCandles.map((e) => e.volume).reduce(max);

        return GestureHandler(
          style: style,
          candlesCount: candles.length,
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          controller: controller,
          candlesHighPrice: candlesHighPrice,
          candlesLowPrice: candlesLowPrice,
          viewPort: viewPort,
          onHoveredCandleIndexChange: onHoveredCandleIndexChange,
          builder: (
            BuildContext context,
            double newHigh,
            double newLow,
            double? mouseHoverY,
            bool isPriceScaled,
          ) {
            return Stack(
              children: [
                PriceColumn(
                  style: style,
                  low: newLow,
                  high: newHigh,
                  width: maxWidth,
                  mouseHoverY: mouseHoverY,
                  chartHeight: maxHeight,
                  lastCandle: candles[max(viewPort.scrollIndex, 0)],
                ),
                Positioned(
                  bottom: 0,
                  height: volumeBarsHeight,
                  width: maxWidth - PRICE_BAR_WIDTH,
                  child: VolumeWidget(
                    candles: candles,
                    barWidth: viewPort.candleWidth,
                    index: viewPort.scrollIndex,
                    high: volumeHigh,
                    bearColor: style.secondaryBear,
                    bullColor: style.secondaryBull,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  height: maxHeight,
                  width: maxWidth - PRICE_BAR_WIDTH,
                  child: HighLowAnimator(
                    candlesHighPrice: newHigh,
                    candlesLowPrice: newLow,
                    diableAnimation: isPriceScaled,
                    builder: (BuildContext context, double high, double low) {
                      return RepaintBoundary(
                        child: CandleStickWidget(
                          candles: candles,
                          candleWidth: viewPort.candleWidth,
                          index: viewPort.scrollIndex,
                          high: high,
                          low: low,
                          bearColor: style.primaryBear,
                          bullColor: style.primaryBull,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 12,
                  child: TopPanel(
                    style: style,
                    currentCandle: hoveredCandleIndex != null
                        ? candles[hoveredCandleIndex!]
                        : null,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
