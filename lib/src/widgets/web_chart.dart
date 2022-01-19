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
class WebChart extends StatefulWidget {
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

  WebChart({
    required this.onScaleUpdate,
    required this.onHorizontalDragUpdate,
    required this.candleWidth,
    required this.candles,
    required this.index,
    required this.onPanDown,
    required this.onPanEnd,
  });

  @override
  State<WebChart> createState() => _WebChartState();
}

class _WebChartState extends State<WebChart> {
  double? mouseHoverX;
  double? mouseHoverY;
  bool isDragging = false;

  void _onMouseExit(PointerEvent details) {
    setState(() {
      mouseHoverX = null;
      mouseHoverY = null;
    });
  }

  void _onMouseHover(PointerEvent details) {
    setState(() {
      mouseHoverX = details.localPosition.dx;
      mouseHoverY = details.localPosition.dy;
    });
  }

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

        if (isDragging) {
          mouseHoverX = null;
          mouseHoverY = null;
        }

        return TweenAnimationBuilder(
          tween: Tween(begin: candlesLowPrice, end: candlesHighPrice),
          duration: Duration(milliseconds: 200),
          builder: (context, double high, _) {
            return TweenAnimationBuilder(
              tween: Tween(begin: candlesHighPrice, end: candlesLowPrice),
              duration: Duration(milliseconds: 200),
              builder: (context, double low, _) {
                final currentCandle = mouseHoverX == null
                    ? null
                    : widget.candles[min(
                        max(
                            (maxWidth - mouseHoverX!) ~/ widget.candleWidth +
                                widget.index,
                            0),
                        widget.candles.length - 1)];
                return Container(
                  color: Theme.of(context).background,
                  child: Stack(
                    children: [
                      TimeRow(
                        indicatorX: mouseHoverX,
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
                      mouseHoverY != null
                          ? Positioned(
                              top: mouseHoverY! - 10,
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
                                        mouseHoverY! < maxHeight * 0.75
                                            ? (high -
                                                    (mouseHoverY! - 20) /
                                                        (maxHeight * 0.75 -
                                                            40) *
                                                        (high - low))
                                                .toStringAsFixed(0)
                                            : HelperFunctions.priceToString(
                                                HelperFunctions.getRoof(
                                                        volumeHigh) *
                                                    (1 -
                                                        (mouseHoverY! -
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
                      mouseHoverY != null
                          ? Positioned(
                              child: DashLine(
                                length: constraints.maxHeight - 20,
                                color: Theme.of(context).grayColor,
                                direction: Axis.vertical,
                                thickness: 0.5,
                              ),
                              left: mouseHoverX,
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
                        child: MouseRegion(
                          onHover: _onMouseHover,
                          onExit: _onMouseExit,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanUpdate: (update) {
                              widget.onHorizontalDragUpdate(
                                  update.localPosition.dx);
                            },
                            onPanEnd: (update) {
                              widget.onPanEnd();
                              setState(() {
                                isDragging = false;
                              });
                            },
                            onPanDown: (update) {
                              widget.onPanDown(update.localPosition.dx);
                              setState(() {
                                isDragging = true;
                              });
                            },
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
