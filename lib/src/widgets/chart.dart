import 'dart:math';
import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/theme/theme_data.dart';
import 'package:candlesticks/src/utils/helper_functions.dart';
import 'package:candlesticks/src/widgets/candle_info_text.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/price_column.dart';
import 'package:candlesticks/src/widgets/time_row.dart';
import 'package:candlesticks/src/widgets/volume_widget.dart';
import 'package:flutter/material.dart';
import '../models/candle.dart';
import 'package:candlesticks/src/constant/scales.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dash_line.dart';

/// This widget manages gestures
/// Calculates the highest and lowest price of visible candles.
/// Updates right-hand side numbers.
/// And pass values down to [CandleStickWidget].
class Chart extends StatelessWidget {
  /// onScaleUpdate callback
  /// called when user scales chart using buttons or scale gesture
  final Function onScaleUpdate;

  /// onHorizontalDragUpdate
  /// callback calls when user scrolls horizontally along the chart
  final Function onHorizontalDragUpdate;

  /// candleWidth controls the width of the single candles.
  /// range: [2...10]
  final double candleWidth;

  /// list of all candles to display in chart
  final List<Candle> candles;

  /// index of the newest candle to be displayed
  /// changes when user scrolls along the chart
  final int index;

  final void Function(PointerEvent) onEnter;

  final void Function(PointerEvent) onHover;

  final void Function(PointerEvent) onExit;

  final double hoverX;
  final double hoverY;

  final void Function(double) onPanDown;
  final void Function() onPanEnd;

  Chart({
    required this.onScaleUpdate,
    required this.onHorizontalDragUpdate,
    required this.candleWidth,
    required this.candles,
    required this.index,
    required this.onEnter,
    required this.onExit,
    required this.onHover,
    required this.hoverX,
    required this.onPanDown,
    required this.onPanEnd,
    required this.hoverY,
  });

  double calcutePriceScale(double height, double high, double low) {
    for (int i = 0; i < scales.length; i++) {
      double newHigh = (high ~/ scales[i] + 1) * scales[i];
      double newLow = (low ~/ scales[i]) * scales[i];
      double range = newHigh - newLow;
      if (height / (range / scales[i]) > MIN_PRICETILE_HEIGHT) {
        return scales[i];
      }
    }
    return 0;
  }

  double calcutePriceIndicatorTopPadding(
      double chartHeight, double low, double high) {
    return chartHeight +
        10 -
        (candles[index >= 0 ? index : 0].close - low) /
            (high - low) *
            chartHeight;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // determine charts width and height
        final double maxWidth = constraints.maxWidth - PRICE_BAR_WIDTH;
        final double maxHeight = constraints.maxHeight - DATE_BAR_HEIGHT;

        // visible candles start and end indexes
        final int candlesStartIndex = max(index, 0);
        final int candlesEndIndex =
            min(maxWidth ~/ candleWidth + index, candles.length - 1);

        // visible candles highest and lowest price
        double candlesHighPrice = 0;
        double candlesLowPrice = double.infinity;
        for (int i = candlesStartIndex; i <= candlesEndIndex; i++) {
          candlesLowPrice = min(candles[i].low, candlesLowPrice);
          candlesHighPrice = max(candles[i].high, candlesHighPrice);
        }

        // calcute priceScale
        double chartHeight = maxHeight * 0.75 - 2 * MAIN_CHART_VERTICAL_PADDING;
        double priceScale =
            calcutePriceScale(chartHeight, candlesHighPrice, candlesLowPrice);

        // high and low calibrations revision
        candlesHighPrice = (candlesHighPrice ~/ priceScale + 1) * priceScale;
        candlesLowPrice = (candlesLowPrice ~/ priceScale) * priceScale;

        // calcute highest volume
        double volumeHigh = 0;
        for (int i = candlesStartIndex; i <= candlesEndIndex; i++) {
          volumeHigh = max(candles[i].volume, volumeHigh);
        }

        return TweenAnimationBuilder(
          tween: Tween(begin: candlesLowPrice, end: candlesHighPrice),
          duration: Duration(milliseconds: 200),
          builder: (context, double high, _) {
            return TweenAnimationBuilder(
              tween: Tween(begin: candlesHighPrice, end: candlesLowPrice),
              duration: Duration(milliseconds: 200),
              builder: (context, double low, _) {
                final currentCandle = candles[min(
                    max((maxWidth - hoverX) ~/ candleWidth + index, 0),
                    candles.length - 1)];
                return Container(
                  color: Theme.of(context).background,
                  child: Stack(
                    children: [
                      TimeRow(
                        indicatorX: hoverX,
                        candles: candles,
                        candleWidth: candleWidth,
                        indicatorTime: currentCandle.date,
                        index: index,
                      ),
                      Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                PriceColumn(
                                  low: candlesLowPrice,
                                  high: candlesHighPrice,
                                  priceScale: priceScale,
                                  width: constraints.maxWidth,
                                  chartHeight: chartHeight,
                                ),
                                AnimatedPositioned(
                                  duration: Duration(microseconds: 300),
                                  right: 0,
                                  top: calcutePriceIndicatorTopPadding(
                                    chartHeight,
                                    low,
                                    high,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: maxWidth,
                                        height: 0.3,
                                        color: candles[index >= 0 ? index : 0]
                                                .isBull
                                            ? Theme.of(context).primaryGreen
                                            : Theme.of(context).primaryRed,
                                      ),
                                      Container(
                                        color: candles[index >= 0 ? index : 0]
                                                .isBull
                                            ? Theme.of(context).primaryGreen
                                            : Theme.of(context).primaryRed,
                                        child: Center(
                                          child: Text(
                                            candles[index >= 0 ? index : 0]
                                                .close
                                                .round()
                                                .toString(),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .currentPriceColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        width: PRICE_BAR_WIDTH,
                                        height: PRICE_INDICATOR_HEIGHT,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color:
                                                  Theme.of(context).grayColor,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 20),
                                          child: Stack(
                                            children: [
                                              RepaintBoundary(
                                                child: CandleStickWidget(
                                                  candles: candles,
                                                  candleWidth: candleWidth,
                                                  index: index,
                                                  high: high,
                                                  low: low,
                                                  bearColor: Theme.of(context)
                                                      .primaryRed,
                                                  bullColor: Theme.of(context)
                                                      .primaryGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: PRICE_BAR_WIDTH,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Theme.of(context).grayColor,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: VolumeWidget(
                                        candles: candles,
                                        barWidth: candleWidth,
                                        index: index,
                                        high:
                                            HelperFunctions.getRoof(volumeHigh),
                                        bearColor:
                                            Theme.of(context).secondaryRed,
                                        bullColor:
                                            Theme.of(context).secondaryGreen,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: DATE_BAR_HEIGHT,
                                        child: Center(
                                          child: Row(
                                            children: [
                                              Text(
                                                "-${HelperFunctions.priceToString(HelperFunctions.getRoof(volumeHigh))}",
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .grayColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  width: 50,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: DATE_BAR_HEIGHT,
                          ),
                        ],
                      ),
                      kIsWeb
                          ? Positioned(
                              top: hoverY - 10,
                              child: Row(
                                children: [
                                  DashLine(
                                    length: maxWidth,
                                    color: Theme.of(context).grayColor,
                                    direction: Axis.horizontal,
                                    thickness: 0.5,
                                  ),
                                  Container(
                                    color: Theme.of(context)
                                        .hoverIndicatorBackgroundColor,
                                    child: Center(
                                      child: Text(
                                        hoverY < maxHeight * 0.75
                                            ? (high -
                                                    (hoverY - 20) /
                                                        (maxHeight * 0.75 -
                                                            40) *
                                                        (high - low))
                                                .toStringAsFixed(0)
                                            : HelperFunctions.priceToString(
                                                HelperFunctions.getRoof(
                                                        volumeHigh) *
                                                    (1 -
                                                        (hoverY -
                                                                maxHeight *
                                                                    0.75 -
                                                                10) /
                                                            (maxHeight * 0.25 -
                                                                10))),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .hoverIndicatorTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    width: 50,
                                    height: 20,
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      kIsWeb
                          ? Positioned(
                              child: Column(
                                children: [
                                  DashLine(
                                    length: constraints.maxHeight - 20,
                                    color: Theme.of(context).grayColor,
                                    direction: Axis.vertical,
                                    thickness: 0.5,
                                  ),
                                ],
                              ),
                              left: hoverX,
                            )
                          : Container(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 12),
                        child: CandleInfoText(candle: currentCandle),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 50, bottom: 20),
                        child: MouseRegion(
                          onEnter: onEnter,
                          onHover: onHover,
                          onExit: onExit,
                          child: GestureDetector(
                            onPanUpdate: (update) {
                              onHorizontalDragUpdate(update.localPosition.dx);
                            },
                            onPanEnd: (update) {
                              onPanEnd();
                            },
                            onPanDown: (update) {
                              onPanDown(update.localPosition.dx);
                            },
                            child: Container(
                              color: Color.fromARGB(1, 255, 255, 255),
                            ),
                          ),
                        ),
                      )
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
