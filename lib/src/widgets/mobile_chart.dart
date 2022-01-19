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

  MobileChart({
    required this.onScaleUpdate,
    required this.onHorizontalDragUpdate,
    required this.candleWidth,
    required this.candles,
    required this.index,
    required this.onPanDown,
    required this.onPanEnd,
  });

  @override
  State<MobileChart> createState() => _MobileChartState();
}

class _MobileChartState extends State<MobileChart> {
  double? longPressX;
  double? longPressY;

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

        // visible candles highest and lowest price
        double candlesHighPrice = 0;
        double candlesLowPrice = double.infinity;
        for (int i = candlesStartIndex; i <= candlesEndIndex; i++) {
          candlesLowPrice = min(widget.candles[i].low, candlesLowPrice);
          candlesHighPrice = max(widget.candles[i].high, candlesHighPrice);
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
          volumeHigh = max(widget.candles[i].volume, volumeHigh);
        }

        if (longPressX != null && longPressY != null) {
          longPressX = max(longPressX!, 0);
          longPressX = min(longPressX!, maxWidth);
          longPressY = max(longPressY!, 0);
          longPressX = min(longPressX!, maxHeight);
        }

        return TweenAnimationBuilder(
          tween: Tween(begin: candlesLowPrice, end: candlesHighPrice),
          duration: Duration(milliseconds: 200),
          builder: (context, double high, _) {
            return TweenAnimationBuilder(
              tween: Tween(begin: candlesHighPrice, end: candlesLowPrice),
              duration: Duration(milliseconds: 200),
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
                                              vertical:
                                                  MAIN_CHART_VERTICAL_PADDING),
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
                                            ? (high -
                                                    (longPressY! - 20) /
                                                        (maxHeight * 0.75 -
                                                            40) *
                                                        (high - low))
                                                .toStringAsFixed(0)
                                            : HelperFunctions.priceToString(
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
                                    width: 50,
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
                          onPanUpdate: (update) {
                            widget.onHorizontalDragUpdate(
                                update.localPosition.dx);
                          },
                          onPanEnd: (update) {
                            widget.onPanEnd();
                          },
                          onLongPressEnd: (_) {
                            setState(() {
                              longPressX = null;
                              longPressY = null;
                            });
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
                          onPanDown: (update) {
                            widget.onPanDown(update.localPosition.dx);
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
