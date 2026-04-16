import 'dart:math';
import 'package:candlesticks/src/main.dart';
import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/utils/helper_functions.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/price_column.dart';
import 'package:candlesticks/src/widgets/time_row.dart';
import 'package:candlesticks/src/widgets/top_panel.dart';
import 'package:candlesticks/src/widgets/volume_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/candle.dart';

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
          candlesHighPrice = inRangeCandles.map((c) => c.high).reduce(max);
          candlesLowPrice = inRangeCandles.map((c) => c.low).reduce(min);
          double diff = candlesHighPrice - candlesLowPrice;
          candlesHighPrice += diff * 0.1;
          candlesLowPrice -= diff * 0.1;
        } else if (widget.chartAdjust == ChartAdjust.fullRange) {
          candlesHighPrice = widget.candles.map((c) => c.high).reduce(max);
          candlesLowPrice = widget.candles.map((c) => c.low).reduce(min);
          double diff = candlesHighPrice - candlesLowPrice;
          candlesHighPrice += diff * 0.1;
          candlesLowPrice -= diff * 0.1;
        }

        if (candlesHighPrice == candlesLowPrice) {
          candlesHighPrice += 10;
          candlesLowPrice -= 10;
        }

        // calculate priceScale
        double chartHeight = maxHeight * 0.75;

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
                final hoveredCandle = mouseHoverX == null
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
                      Padding(
                        padding: const EdgeInsets.only(
                          right: PRICE_BAR_WIDTH,
                        ), // padding rigth PRICE_BAR_WIDTH
                        child: TimeRow(
                          style: widget.style,
                          mouseHoverX: showHoverIndicator ? mouseHoverX : null,
                          candles: widget.candles,
                          candleWidth: widget.candleWidth,
                          indicatorTime: hoveredCandle?.date,
                          index: widget.index,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: DATE_BAR_HEIGHT,
                        ), // padding bottom DATE_BAR_HEIGHT
                        child: PriceColumn(
                          style: widget.style,
                          low: candlesLowPrice,
                          high: candlesHighPrice,
                          width: constraints.maxWidth,
                          mouseHoverY: showHoverIndicator ? mouseHoverY : null,
                          volumeHigh: volumeHigh,
                          chartHeight: chartHeight,
                          lastCandle: widget
                              .candles[widget.index < 0 ? 0 : widget.index],
                          onScale: (delta) {
                            if (manualScaleHigh == null) {
                              manualScaleHigh = candlesHighPrice;
                              manualScaleLow = candlesLowPrice;
                            }
                            setState(() {
                              double deltaPrice = delta /
                                  chartHeight *
                                  (manualScaleHigh! - manualScaleLow!);
                              manualScaleHigh = manualScaleHigh! + deltaPrice;
                              manualScaleLow = manualScaleLow! - deltaPrice;
                            });
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
                                color: widget.style.borderColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                flex: 3,
                                child: RepaintBoundary(
                                  child: CandleStickWidget(
                                    candles: widget.candles,
                                    candleWidth: widget.candleWidth,
                                    index: widget.index,
                                    high: high,
                                    low: low,
                                    bearColor: widget.style.primaryBear,
                                    bullColor: widget.style.primaryBull,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                  ), // todo: explain why
                                  child: VolumeWidget(
                                    candles: widget.candles,
                                    barWidth: widget.candleWidth,
                                    index: widget.index,
                                    high: HelperFunctions.getRoof(volumeHigh),
                                    bearColor: widget.style.secondaryBear,
                                    bullColor: widget.style.secondaryBull,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                          currentCandle: hoveredCandle,
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
                            backgroundColor:
                                widget.style.hoverIndicatorBackgroundColor,
                            foregroundColor: widget.style.secondaryTextColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
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
