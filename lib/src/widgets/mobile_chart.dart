import 'dart:math';

import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/main_window_indicator.dart';
import 'package:candlesticks/src/utils/helper_functions.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/mainwindow_indicator_widget.dart';
import 'package:candlesticks/src/widgets/price_column.dart';
import 'package:candlesticks/src/widgets/time_row.dart';
import 'package:candlesticks/src/widgets/top_panel.dart';
import 'package:candlesticks/src/widgets/volume_widget.dart';
import 'package:flutter/material.dart';

import 'dash_line.dart';

class MobileChart extends StatefulWidget {
  final Function onScaleUpdate;
  final Function onHorizontalDragUpdate;
  final double candleWidth;
  final List<Candle> candles;
  final int index;
  final MainWindowDataContainer mainWindowDataContainer;
  final ChartAdjust chartAdjust;
  final CandleSticksStyle style;
  final void Function(double) onPanDown;
  final void Function() onPanEnd;
  final void Function(String)? onRemoveIndicator;
  final Function() onReachEnd;

  /// ✱ NEW – set to `false` to hide tooltip / cross‑hair
  final bool showTooltip;

  MobileChart({
    super.key,
    required this.style,
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
    this.showTooltip = true,
  });

  @override
  State<MobileChart> createState() => _MobileChartState();
}

class _MobileChartState extends State<MobileChart> {
  double? longPressX;
  double? longPressY;

  double? manualScaleHigh;
  double? manualScaleLow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth  = constraints.maxWidth  - PRICE_BAR_WIDTH;
        final maxHeight = constraints.maxHeight - DATE_BAR_HEIGHT;

        final start = max(widget.index, 0);
        final end   = min(maxWidth ~/ widget.candleWidth + widget.index,
                          widget.candles.length - 1);

        if (end == widget.candles.length - 1) {
          // ask upstream to load more once we reach the right‑edge
          Future(widget.onReachEnd);
        }

        final visible = widget.candles.getRange(start, end + 1).toList();

        double highPrice, lowPrice;
        if (manualScaleHigh != null) {
          highPrice = manualScaleHigh!;
          lowPrice  = manualScaleLow!;
        } else if (widget.chartAdjust == ChartAdjust.visibleRange) {
          highPrice = widget.mainWindowDataContainer.highs
              .getRange(start, end + 1).reduce(max);
          lowPrice  = widget.mainWindowDataContainer.lows
              .getRange(start, end + 1).reduce(min);
        } else {
          highPrice = widget.mainWindowDataContainer.highs.reduce(max);
          lowPrice  = widget.mainWindowDataContainer.lows.reduce(min);
        }

        if (highPrice == lowPrice) {
          highPrice += 10;
          lowPrice  -= 10;
        }

        final chartHeight = maxHeight * .75 - 2 * MAIN_CHART_VERTICAL_PADDING;
        final volumeHigh  = visible.map((c) => c.volume).reduce(max);

        // clamp overlay inside chart bounds
        if (longPressX != null && longPressY != null) {
          longPressX = longPressX!.clamp(0.0, maxWidth);
          longPressY = longPressY!.clamp(0.0, maxHeight);
        }

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: manualScaleHigh == null ? 300 : 0),
          tween   : Tween(begin: highPrice, end: highPrice),
          builder : (context, high, _) {
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: manualScaleHigh == null ? 300 : 0),
              tween   : Tween(begin: lowPrice, end: lowPrice),
              builder : (context, low, _) {
                // current candle under cross‑hair
                final current = (widget.showTooltip && longPressX != null)
                    ? widget.candles[min(
                        max((maxWidth - longPressX!) ~/ widget.candleWidth +
                            widget.index, 0), widget.candles.length - 1)]
                    : null;

                return Container(
                  color: widget.style.background,
                  child: Stack(
                    children: [
                      TimeRow(
                        style        : widget.style,
                        indicatorX   : widget.showTooltip ? longPressX : null,
                        candles      : widget.candles,
                        candleWidth  : widget.candleWidth,
                        indicatorTime: current?.date,
                        index        : widget.index,
                      ),

                      /// ────────── MAIN + VOLUME CHARTS ──────────
                      Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                PriceColumn(
                                  style      : widget.style,
                                  low        : lowPrice,
                                  high       : highPrice,
                                  width      : constraints.maxWidth,
                                  chartHeight: chartHeight,
                                  lastCandle : widget.candles[
                                      widget.index < 0 ? 0 : widget.index],
                                  onScale    : (delta) {
                                    if (manualScaleHigh == null) {
                                      manualScaleHigh = highPrice;
                                      manualScaleLow  = lowPrice;
                                    }
                                    setState(() {
                                      final d = delta / chartHeight *
                                          (manualScaleHigh! - manualScaleLow!);
                                      manualScaleHigh = manualScaleHigh! + d;
                                      manualScaleLow  = manualScaleLow! - d;
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
                                          duration: const Duration(milliseconds: 300),
                                          padding : const EdgeInsets.symmetric(
                                              vertical: MAIN_CHART_VERTICAL_PADDING),
                                          child: RepaintBoundary(
                                            child: Stack(
                                              children: [
                                                MainWindowIndicatorWidget(
                                                  indicatorDatas: widget
                                                      .mainWindowDataContainer
                                                      .indicatorComponentData,
                                                  index       : widget.index,
                                                  candleWidth : widget.candleWidth,
                                                  low         : low,
                                                  high        : high,
                                                ),
                                                CandleStickWidget(
                                                  candles    : widget.candles,
                                                  candleWidth: widget.candleWidth,
                                                  index      : widget.index,
                                                  high       : high,
                                                  low        : low,
                                                  bearColor  : widget.style.primaryBear,
                                                  bullColor  : widget.style.primaryBull,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: PRICE_BAR_WIDTH),
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
                                      padding: const EdgeInsets.only(top: 10),
                                      child: VolumeWidget(
                                        candles   : widget.candles,
                                        barWidth  : widget.candleWidth,
                                        index     : widget.index,
                                        high      : HelperFunctions.getRoof(volumeHigh),
                                        bearColor : widget.style.secondaryBear,
                                        bullColor : widget.style.secondaryBull,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width : PRICE_BAR_WIDTH,
                                  child : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: DATE_BAR_HEIGHT,
                                        child : Center(
                                          child: Text(
                                            "-${HelperFunctions.addMetricPrefix(HelperFunctions.getRoof(volumeHigh))}",
                                            style: TextStyle(
                                              color: widget.style.borderColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: DATE_BAR_HEIGHT),
                        ],
                      ),

                      /// ────────── CROSS‑HAIR OVERLAY ──────────
                      if (widget.showTooltip && longPressY != null)
                        Positioned(
                          top: longPressY! - 10,
                          child: Row(
                            children: [
                              DashLine(
                                length   : maxWidth,
                                color    : widget.style.borderColor,
                                direction: Axis.horizontal,
                                thickness: 0.5,
                              ),
                              Container(
                                color: Colors.grey.shade800,
                                width : PRICE_BAR_WIDTH,
                                height: 20,
                                child : Center(
                                  child: Text(
                                    longPressY! < maxHeight * .75
                                        ? HelperFunctions.priceToString(
                                            high -
                                                (longPressY! -
                                                        MAIN_CHART_VERTICAL_PADDING) /
                                                    (maxHeight * .75 -
                                                        2 * MAIN_CHART_VERTICAL_PADDING) *
                                                    (high - low),
                                          )
                                        : HelperFunctions.addMetricPrefix(
                                            HelperFunctions.getRoof(volumeHigh) *
                                                (1 -
                                                    (longPressY! -
                                                            maxHeight * .75 -
                                                            10) /
                                                        (maxHeight * .25 - 10)),
                                          ),
                                    style: TextStyle(
                                      color: widget.style.secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (widget.showTooltip && longPressX != null)
                        Positioned(
                          right: (maxWidth - longPressX!) ~/
                                      widget.candleWidth *
                                      widget.candleWidth +
                                  PRICE_BAR_WIDTH,
                          child: Container(
                            width : widget.candleWidth,
                            height: maxHeight,
                            color : widget.style.mobileCandleHoverColor,
                          ),
                        ),

                      /// ────────── GESTURES ──────────
                      Padding(
                        padding: const EdgeInsets.only(right: 50, bottom: 20),
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onScaleStart: (d) =>
                              widget.onPanDown(d.localFocalPoint.dx),
                          onScaleUpdate: (details) {
                            if (details.scale == 1) {
                              widget.onHorizontalDragUpdate(details.focalPoint.dx);
                              if (manualScaleHigh != null) {
                                setState(() {
                                  final d = details.focalPointDelta.dy /
                                      chartHeight *
                                      (manualScaleHigh! - manualScaleLow!);
                                  manualScaleHigh = manualScaleHigh! + d;
                                  manualScaleLow  = manualScaleLow! + d;
                                });
                              }
                            }
                            widget.onScaleUpdate(details.scale);
                          },
                          onScaleEnd: (_) => widget.onPanEnd(),

                          // only track long‑press when tooltip enabled
                          onLongPressStart: widget.showTooltip
                              ? (d) => setState(() {
                                    longPressX = d.localPosition.dx;
                                    longPressY = d.localPosition.dy;
                                  })
                              : null,
                          onLongPressMoveUpdate: widget.showTooltip
                              ? (d) => setState(() {
                                    longPressX = d.localPosition.dx;
                                    longPressY = d.localPosition.dy;
                                  })
                              : null,
                          onLongPressEnd: widget.showTooltip
                              ? (_) => setState(() {
                                    longPressX = null;
                                    longPressY = null;
                                  })
                              : null,
                        ),
                      ),

                      /// ────────── TOP INFO BAR ──────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 12),
                        child: TopPanel(
                          style        : widget.style,
                          onRemoveIndicator: widget.onRemoveIndicator,
                          currentCandle    : current,
                          indicators       : widget
                              .mainWindowDataContainer.indicators,
                          toggleIndicatorVisibility: (name) {
                            setState(() {
                              widget.mainWindowDataContainer
                                  .toggleIndicatorVisibility(name);
                            });
                          },
                          unvisibleIndicators:
                              widget.mainWindowDataContainer.unvisibleIndicators,
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


