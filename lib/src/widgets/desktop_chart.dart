import 'dart:math';
import 'package:candlesticks/src/main.dart';
import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/models/main_window_indicator.dart';
import 'package:candlesticks/src/utils/helper_functions.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/mainwindow_indicator_widget.dart';
import 'package:candlesticks/src/widgets/price_column.dart';
import 'package:candlesticks/src/widgets/time_row.dart';
import 'package:candlesticks/src/widgets/top_panel.dart';
import 'package:candlesticks/src/widgets/volume_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/candle.dart';
import 'dash_line.dart';

/// This widget manages gestures
/// Calculates the highest and lowest price of visible candles.
/// Updates right-hand side numbers.
/// And pass values down to [CandleStickWidget].
class DesktopChart extends StatefulWidget {
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

  /// Will chart resize vertically by visible range
  /// or by the whole dataset
  final ChartAdjust chartAdjust;

  final CandleSticksStyle style;

  final void Function(double) onPanDown;
  final void Function() onPanEnd;

  final Function() onReachEnd;

  /// holds main window indicators data and high and low prices.
  final MainWindowDataContainer mainWindowDataContainer;

  final void Function(String)? onRemoveIndicator;

  DesktopChart({
    required this.onScaleUpdate,
    required this.onHorizontalDragUpdate,
    required this.candleWidth,
    required this.candles,
    required this.index,
    required this.chartAdjust,
    required this.onPanDown,
    required this.onPanEnd,
    required this.onReachEnd,
    required this.mainWindowDataContainer,
    required this.onRemoveIndicator,
    required this.style,
  });

  @override
  State<DesktopChart> createState() => _DesktopChartState();
}

class _DesktopChartState extends State<DesktopChart> {
  double? mouseHoverX;
  double? mouseHoverY;
  bool isDragging = false;
  bool showHoverIndicator = true;
  double? manualScaleHigh;
  double? manualScaleLow;

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

        double candlesHighPrice = 0;
        double candlesLowPrice = 0;
        if (manualScaleHigh != null) {
          candlesHighPrice = manualScaleHigh!;
          candlesLowPrice = manualScaleLow!;
        } else if (widget.chartAdjust == ChartAdjust.visibleRange) {
          candlesHighPrice = widget.mainWindowDataContainer.highs
              .getRange(candlesStartIndex, candlesEndIndex + 1)
              .reduce(max);
          candlesLowPrice = widget.mainWindowDataContainer.lows
              .getRange(candlesStartIndex, candlesEndIndex + 1)
              .reduce(min);
        } else if (widget.chartAdjust == ChartAdjust.fullRange) {
          candlesHighPrice = widget.mainWindowDataContainer.highs.reduce(max);
          candlesLowPrice = widget.mainWindowDataContainer.lows.reduce(min);
        }

        if (candlesHighPrice == candlesLowPrice) {
          candlesHighPrice += 10;
          candlesLowPrice -= 10;
        }

        // calculate priceScale
        double chartHeight =
            maxHeight * 0.75 - 2 * (MAIN_CHART_VERTICAL_PADDING);

        // calculate highest volume
        double volumeHigh = inRangeCandles.map((e) => e.volume).reduce(max);

        return TweenAnimationBuilder(
          tween: Tween(begin: candlesHighPrice, end: candlesHighPrice),
          duration: Duration(milliseconds: manualScaleHigh == null ? 300 : 0),
          builder: (context, double high, _) {
            return TweenAnimationBuilder(
              tween: Tween(begin: candlesLowPrice, end: candlesLowPrice),
              duration:
                  Duration(milliseconds: manualScaleHigh == null ? 300 : 0),
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
                  color: widget.style.background,
                  child: Stack(
                    children: [
                      TimeRow(
                        style: widget.style,
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
                                  style: widget.style,
                                  low: candlesLowPrice,
                                  high: candlesHighPrice,
                                  width: constraints.maxWidth,
                                  chartHeight: chartHeight,
                                  lastCandle: widget.candles[
                                      widget.index < 0 ? 0 : widget.index],
                                  onScale: (delta) {
                                    if (manualScaleHigh == null) {
                                      manualScaleHigh = candlesHighPrice;
                                      manualScaleLow = candlesLowPrice;
                                    }
                                    setState(() {
                                      double deltaPrice = delta /
                                          chartHeight *
                                          (manualScaleHigh! - manualScaleLow!);
                                      manualScaleHigh =
                                          manualScaleHigh! + deltaPrice;
                                      manualScaleLow =
                                          manualScaleLow! - deltaPrice;
                                    });
                                  },
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: widget.style.borderColor,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: AnimatedPadding(
                                          duration: Duration(milliseconds: 300),
                                          padding: EdgeInsets.symmetric(
                                              vertical:
                                                  MAIN_CHART_VERTICAL_PADDING),
                                          child: RepaintBoundary(
                                            child: Stack(
                                              children: [
                                                MainWindowIndicatorWidget(
                                                  indicatorDatas: widget
                                                      .mainWindowDataContainer
                                                      .indicatorComponentData,
                                                  index: widget.index,
                                                  candleWidth:
                                                      widget.candleWidth,
                                                  low: low,
                                                  high: high,
                                                ),
                                                CandleStickWidget(
                                                  candles: widget.candles,
                                                  candleWidth:
                                                      widget.candleWidth,
                                                  index: widget.index,
                                                  high: high,
                                                  low: low,
                                                  bearColor:
                                                      widget.style.primaryBear,
                                                  bullColor:
                                                      widget.style.primaryBull,
                                                ),
                                              ],
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
                                          color: widget.style.borderColor,
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
                                        bearColor: widget.style.secondaryBear,
                                        bullColor: widget.style.secondaryBull,
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
                                                  color:
                                                      widget.style.borderColor,
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
                      mouseHoverY != null && showHoverIndicator
                          ? Positioned(
                              top: mouseHoverY! - 10,
                              child: Row(
                                children: [
                                  DashLine(
                                    length: maxWidth,
                                    color: widget.style.borderColor,
                                    direction: Axis.horizontal,
                                    thickness: 0.5,
                                  ),
                                  Container(
                                    color: widget
                                        .style.hoverIndicatorBackgroundColor,
                                    child: Center(
                                      child: Text(
                                        mouseHoverY! < maxHeight * 0.75
                                            ? HelperFunctions.priceToString(high -
                                                (mouseHoverY! -
                                                        MAIN_CHART_VERTICAL_PADDING) /
                                                    (maxHeight * 0.75 -
                                                        2 *
                                                            MAIN_CHART_VERTICAL_PADDING) *
                                                    (high - low))
                                            : HelperFunctions.addMetricPrefix(
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
                                          color:
                                              widget.style.secondaryTextColor,
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
                      mouseHoverX != null && showHoverIndicator
                          ? Positioned(
                              child: DashLine(
                                length: constraints.maxHeight - 20,
                                color: widget.style.borderColor,
                                direction: Axis.vertical,
                                thickness: 0.5,
                              ),
                              left: mouseHoverX,
                            )
                          : Container(),
                      Padding(
                        padding: const EdgeInsets.only(right: 50, bottom: 20),
                        child: Listener(
                          onPointerSignal: (pointerSignal) {
                            if (pointerSignal is PointerScrollEvent) {
                              widget.onScaleUpdate(
                                  pointerSignal.scrollDelta.direction * -1);
                            }
                          },
                          child: MouseRegion(
                            cursor: isDragging
                                ? SystemMouseCursors.grabbing
                                : SystemMouseCursors.precise,
                            onHover: _onMouseHover,
                            onExit: _onMouseExit,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onPanUpdate: (update) {
                                mouseHoverX = update.localPosition.dx;
                                mouseHoverY = update.localPosition.dy;
                                widget.onHorizontalDragUpdate(
                                    update.localPosition.dx);
                                setState(() {
                                  if (manualScaleHigh != null) {
                                    double deltaPrice = update.delta.dy /
                                        chartHeight *
                                        (manualScaleHigh! - manualScaleLow!);
                                    manualScaleHigh =
                                        manualScaleHigh! + deltaPrice;
                                    manualScaleLow =
                                        manualScaleLow! + deltaPrice;
                                  }
                                });
                              },
                              onPanEnd: (update) {
                                widget.onPanEnd();
                                setState(() {
                                  isDragging = false;
                                });
                                Future.delayed(Duration(milliseconds: 300), () {
                                  setState(() {
                                    showHoverIndicator = true;
                                  });
                                });
                              },
                              onPanDown: (update) {
                                widget.onPanDown(update.localPosition.dx);
                                setState(() {
                                  isDragging = true;
                                  showHoverIndicator = false;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 12),
                        child: TopPanel(
                          style: widget.style,
                          onRemoveIndicator: widget.onRemoveIndicator,
                          currentCandle: currentCandle,
                          indicators: widget.mainWindowDataContainer.indicators,
                          toggleIndicatorVisibility: (indicatorName) {
                            setState(() {
                              widget.mainWindowDataContainer
                                  .toggleIndicatorVisibility(indicatorName);
                            });
                          },
                          unvisibleIndicators: widget
                              .mainWindowDataContainer.unvisibleIndicators,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        width: PRICE_BAR_WIDTH,
                        height: 20,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            primary: widget.style.hoverIndicatorBackgroundColor,
                          ),
                          child: Text(
                            "Auto",
                            style: TextStyle(
                              color: widget.style.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: manualScaleHigh == null
                              ? null
                              : () {
                                  setState(() {
                                    manualScaleHigh = null;
                                    manualScaleLow = null;
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
