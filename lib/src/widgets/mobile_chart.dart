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
import 'dash_line.dart';

/// This widget manages gestures
/// Calculates the highest and lowest price of visible candles.
/// Updates right-hand side numbers.
/// And pass values down to [CandleStickWidget].
class MobileChart extends StatefulWidget {
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

  final void Function(double) onPanDown;
  final void Function() onPanEnd;

  final Function() onReachEnd;

  MobileChart({
    required this.onScaleUpdate,
    required this.onHorizontalDragUpdate,
    required this.candleWidth,
    required this.candles,
    required this.index,
    required this.onPanDown,
    required this.onPanEnd,
    required this.onReachEnd,
  });

  @override
  State<MobileChart> createState() => _MobileChartState();
}

class _MobileChartState extends State<MobileChart> {
  double? longPressX;
  double? longPressY;
  double additionalVerticalPadding = 0;

  double calcutePriceScale(double height, double high, double low) {
    int minTiles = (height / MIN_PRICETILE_HEIGHT).floor();
    minTiles = max(2, minTiles);
    double sizeRange = high - low;
    double minStepSize = sizeRange / minTiles;
    double base =
        pow(10, HelperFunctions.log10(minStepSize).floor()).toDouble();

    if (2 * base > minStepSize) return 2 * base;
    if (5 * base > minStepSize) return 5 * base;
    return 10 * base;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // determine charts width and height
        final double maxWidth = constraints.maxWidth - PRICE_BAR_WIDTH;
        final double maxHeight = constraints.maxHeight - DATE_BAR_HEIGHT;

        // visible candles start and end indexes
        final int candlesStartIndex = max(widget.index, 0);
        final int candlesEndIndex = min(
            maxWidth ~/ widget.candleWidth + widget.index,
            widget.candles.length - 1);

        if (candlesEndIndex == widget.candles.length - 1) {
          Future(() {
            widget.onReachEnd();
          });
        }

        List<Candle> inRangeCandles = widget.candles
            .getRange(candlesStartIndex, candlesEndIndex + 1)
            .toList();

        // visible candles highest and lowest price
        double candlesHighPrice = inRangeCandles.map((e) => e.high).reduce(max);
        double candlesLowPrice = inRangeCandles.map((e) => e.low).reduce(min);

        // calcute priceScale
        double chartHeight = maxHeight * 0.75 -
            2 * (MAIN_CHART_VERTICAL_PADDING + additionalVerticalPadding);
        double priceScale =
            calcutePriceScale(chartHeight, candlesHighPrice, candlesLowPrice);

        // high and low calibrations revision
        candlesHighPrice = (candlesHighPrice ~/ priceScale + 1) * priceScale;
        candlesLowPrice = (candlesLowPrice ~/ priceScale) * priceScale;

        // calcute highest volume
        double volumeHigh = 0;
        for (int i = candlesStartIndex; i <= candlesEndIndex; i++) {
          volumeHigh = max(widget.candles[i].volume, volumeHigh);
        }

        if (longPressX != null && longPressY != null) {
          longPressX = max(longPressX!, 0);
          longPressX = min(longPressX!, maxWidth);
          longPressY = max(longPressY!, 0);
          longPressX = min(longPressX!, maxHeight);
        }

        return TweenAnimationBuilder(
          tween: Tween(begin: candlesHighPrice, end: candlesHighPrice),
          duration: Duration(milliseconds: 300),
          builder: (context, double high, _) {
            return TweenAnimationBuilder(
              tween: Tween(begin: candlesLowPrice, end: candlesLowPrice),
              duration: Duration(milliseconds: 300),
              builder: (context, double low, _) {
                final currentCandle = longPressX == null
                    ? null
                    : widget.candles[min(
                        max(
                            (maxWidth - longPressX!) ~/ widget.candleWidth +
                                widget.index,
                            0),
                        widget.candles.length - 1)];
                return Container(
                  color: Theme.of(context).background,
                  child: Stack(
                    children: [
                      TimeRow(
                        indicatorX: longPressX,
                        candles: widget.candles,
                        candleWidth: widget.candleWidth,
                        indicatorTime: currentCandle?.date,
                        index: widget.index,
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
                                  lastCandle: widget.candles[
                                      widget.index < 0 ? 0 : widget.index],
                                  onScale: (delta) {
                                    setState(() {
                                      additionalVerticalPadding += delta;
                                      additionalVerticalPadding = min(
                                          maxHeight / 4,
                                          additionalVerticalPadding);
                                      additionalVerticalPadding =
                                          max(0, additionalVerticalPadding);
                                    });
                                  },
                                  additionalVerticalPadding:
                                      additionalVerticalPadding,
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
                                        child: AnimatedPadding(
                                          duration: Duration(milliseconds: 300),
                                          padding: EdgeInsets.symmetric(
                                              vertical:
                                                  MAIN_CHART_VERTICAL_PADDING +
                                                      additionalVerticalPadding),
                                          child: RepaintBoundary(
                                            child: CandleStickWidget(
                                              candles: widget.candles,
                                              candleWidth: widget.candleWidth,
                                              index: widget.index,
                                              high: high,
                                              low: low,
                                              bearColor:
                                                  Theme.of(context).primaryRed,
                                              bullColor: Theme.of(context)
                                                  .primaryGreen,
                                            ),
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
                                        candles: widget.candles,
                                        barWidth: widget.candleWidth,
                                        index: widget.index,
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
                                                "-${HelperFunctions.addMetricPrefix(HelperFunctions.getRoof(volumeHigh))}",
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
                                  width: PRICE_BAR_WIDTH,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: DATE_BAR_HEIGHT,
                          ),
                        ],
                      ),
                      longPressY != null
                          ? Positioned(
                              top: longPressY! - 10,
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
                                        longPressY! < maxHeight * 0.75
                                            ? HelperFunctions.priceToString(
                                                high -
                                                    (longPressY! - 20) /
                                                        (maxHeight * 0.75 -
                                                            40) *
                                                        (high - low))
                                            : HelperFunctions.addMetricPrefix(
                                                HelperFunctions.getRoof(
                                                        volumeHigh) *
                                                    (1 -
                                                        (longPressY! -
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
                                    width: PRICE_BAR_WIDTH,
                                    height: 20,
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      longPressX != null
                          ? Positioned(
                              child: Container(
                                width: widget.candleWidth,
                                height: maxHeight,
                                color: Theme.of(context).gold.withOpacity(0.2),
                              ),
                              right: (maxWidth - longPressX!) ~/
                                      widget.candleWidth *
                                      widget.candleWidth +
                                  PRICE_BAR_WIDTH,
                            )
                          : Container(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 12),
                        child: currentCandle != null
                            ? CandleInfoText(candle: currentCandle)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 50, bottom: 20),
                        child: GestureDetector(
                          onLongPressEnd: (_) {
                            setState(() {
                              longPressX = null;
                              longPressY = null;
                            });
                          },
                          onScaleEnd: (_) {
                            widget.onPanEnd();
                          },
                          onScaleUpdate: (details) {
                            if (details.scale == 1) {
                              widget.onHorizontalDragUpdate(
                                  details.focalPoint.dx);
                            }
                            widget.onScaleUpdate(details.scale);
                          },
                          onScaleStart: (details) {
                            widget.onPanDown(details.localFocalPoint.dx);
                          },
                          onLongPressStart: (LongPressStartDetails details) {
                            setState(() {
                              longPressX = details.localPosition.dx;
                              longPressY = details.localPosition.dy;
                            });
                          },
                          behavior: HitTestBehavior.translucent,
                          onLongPressMoveUpdate:
                              (LongPressMoveUpdateDetails details) {
                            setState(() {
                              longPressX = details.localPosition.dx;
                              longPressY = details.localPosition.dy;
                            });
                          },
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
