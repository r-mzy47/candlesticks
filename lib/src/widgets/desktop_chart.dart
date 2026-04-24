import 'dart:math';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/main.dart';
import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/gesture_handler.dart';
import 'package:candlesticks/src/widgets/high_low_animator.dart';
import 'package:candlesticks/src/widgets/price_column.dart';
import 'package:candlesticks/src/widgets/time_row.dart';
import 'package:candlesticks/src/widgets/top_panel.dart';
import 'package:candlesticks/src/widgets/volume_widget.dart';
import 'package:flutter/material.dart';
import '../models/candle.dart';

/// This widget manages gestures
/// Calculates the highest and lowest price of visible candles.
/// Updates right-hand side numbers.
/// And pass values down to [CandleStickWidget].
class DesktopChart extends StatelessWidget {
  /// list of all candles to display in chart
  final List<Candle> candles;

  /// Will chart resize vertically by visible range
  /// or by the whole dataset
  final ChartAdjust chartAdjust;

  final CandleSticksStyle style;

  final Function() onReachEnd;

  final CandlesticksController controller;

  DesktopChart({
    required this.candles,
    required this.chartAdjust,
    required this.onReachEnd,
    required this.style,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // determine charts width and height
        final double maxWidth = constraints.maxWidth - PRICE_BAR_WIDTH;
        final double maxHeight = constraints.maxHeight - DATE_BAR_HEIGHT;

        final double volumeBarsHeight = maxHeight * 0.2;

        return ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, viewPort, child) {
            return TweenAnimationBuilder<double>(
              tween: Tween(end: viewPort.candleWidth),
              duration: const Duration(milliseconds: 120),
              builder: (context, animatedWidth, _) {
                final animatedViewport =
                    viewPort.copyWith(candleWidth: animatedWidth);

                // visible candles start and end indexes
                final int candlesStartIndex =
                    max(animatedViewport.scrollIndex, 0);
                final int candlesEndIndex = min(
                    maxWidth ~/ animatedViewport.candleWidth +
                        animatedViewport.scrollIndex,
                    candles.length - 1);

                if (candlesEndIndex == candles.length - 1) {
                  Future(() {
                    onReachEnd();
                  });
                }

                List<Candle> inRangeCandles = candles
                    .getRange(candlesStartIndex, candlesEndIndex + 1)
                    .toList();

                double candlesHighPrice = 0;
                double candlesLowPrice = 0;

                if (chartAdjust == ChartAdjust.visibleRange) {
                  candlesHighPrice =
                      inRangeCandles.map((c) => c.high).reduce(max);
                  candlesLowPrice =
                      inRangeCandles.map((c) => c.low).reduce(min);
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
                double volumeHigh =
                    inRangeCandles.map((e) => e.volume).reduce(max);

                return GestureHandler(
                  style: style,
                  candlesCount: candles.length,
                  chartHeight: maxHeight,
                  controller: controller,
                  candlesHighPrice: candlesHighPrice,
                  candlesLowPrice: candlesLowPrice,
                  viewPort: viewPort,
                  builder: (
                    BuildContext context,
                    double newHigh,
                    double newLow,
                    double? mouseHoverX,
                    double? mouseHoverY,
                    bool showHoverIndicator,
                    bool isPriceScaled,
                    void Function(double, double, double) onPriceBarScale,
                  ) {
                    final hoveredCandle = mouseHoverX == null
                        ? null
                        : candles[min(
                            max(
                                (maxWidth - mouseHoverX) ~/
                                        animatedViewport.candleWidth +
                                    animatedViewport.scrollIndex,
                                0),
                            candles.length - 1)];

                    return Container(
                      color: style.background,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              right: PRICE_BAR_WIDTH,
                            ), // padding rigth PRICE_BAR_WIDTH
                            child: TimeRow(
                              style: style,
                              mouseHoverX:
                                  showHoverIndicator ? mouseHoverX : null,
                              candles: candles,
                              viewport: animatedViewport,
                              indicatorTime: hoveredCandle?.date,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: DATE_BAR_HEIGHT,
                            ), // padding bottom DATE_BAR_HEIGHT
                            child: PriceColumn(
                              style: style,
                              low: newLow,
                              high: newHigh,
                              width: constraints.maxWidth,
                              mouseHoverY:
                                  showHoverIndicator ? mouseHoverY : null,
                              chartHeight: maxHeight,
                              lastCandle:
                                  candles[max(animatedViewport.scrollIndex, 0)],
                              onScale: (value) {
                                onPriceBarScale(
                                    value, candlesHighPrice, candlesLowPrice);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              right: PRICE_BAR_WIDTH - 1,
                              bottom: DATE_BAR_HEIGHT,
                            ), // padding bottom and right for price and date bars
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: style.borderColor,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    bottom: 0,
                                    height: volumeBarsHeight,
                                    width: maxWidth,
                                    child: VolumeWidget(
                                      candles: candles,
                                      barWidth: animatedViewport.candleWidth,
                                      index: animatedViewport.scrollIndex,
                                      high: volumeHigh,
                                      bearColor: style.secondaryBear,
                                      bullColor: style.secondaryBull,
                                    ),
                                  ),
                                  HighLowAnimator(
                                    candlesHighPrice: newHigh,
                                    candlesLowPrice: newLow,
                                    diableAnimation: isPriceScaled,
                                    builder: (BuildContext context, double high,
                                        double low) {
                                      return RepaintBoundary(
                                        child: CandleStickWidget(
                                          candles: candles,
                                          candleWidth:
                                              animatedViewport.candleWidth,
                                          index: animatedViewport.scrollIndex,
                                          high: high,
                                          low: low,
                                          bearColor: style.primaryBear,
                                          bullColor: style.primaryBull,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 12,
                            ),
                            child: TopPanel(
                              style: style,
                              currentCandle: hoveredCandle,
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
      },
    );
  }
}
