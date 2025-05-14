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
  const MobileChart({
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
    this.showLastPrice = true,
  });

  final Function(double scale) onScaleUpdate;
  final Function(double dx)     onHorizontalDragUpdate;
  final double                  candleWidth;
  final List<Candle>            candles;
  final int                     index;
  final MainWindowDataContainer mainWindowDataContainer;
  final ChartAdjust             chartAdjust;
  final CandleSticksStyle       style;
  final void Function(double)   onPanDown;
  final VoidCallback            onPanEnd;
  final void Function(String)?  onRemoveIndicator;
  final VoidCallback            onReachEnd;

  /// show / hide cross‑hair + tooltip
  final bool showTooltip;

  /// show / hide coloured last‑price chip
  final bool showLastPrice;

  @override
  State<MobileChart> createState() => _MobileChartState();
}

class _MobileChartState extends State<MobileChart> {
  double? _crossX;
  double? _crossY;

  double? _manualHigh;
  double? _manualLow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxWidth  = constraints.maxWidth  - PRICE_BAR_WIDTH;
        final maxHeight = constraints.maxHeight - DATE_BAR_HEIGHT;

        final start = max(widget.index, 0);
        final end   = min(maxWidth ~/ widget.candleWidth + widget.index,
                          widget.candles.length - 1);

        // trigger lazy‑load when newest bar is visible
        if (end == widget.candles.length - 1) {
          Future(widget.onReachEnd);
        }

        final visible = widget.candles.getRange(start, end + 1).toList();

        // ── price range ────────────────────────────────────────────
        double hi, lo;
        if (_manualHigh != null) {
          hi = _manualHigh!;
          lo = _manualLow!;
        } else if (widget.chartAdjust == ChartAdjust.visibleRange) {
          hi = widget.mainWindowDataContainer.highs
              .getRange(start, end + 1).reduce(max);
          lo = widget.mainWindowDataContainer.lows
              .getRange(start, end + 1).reduce(min);
        } else {
          hi = widget.mainWindowDataContainer.highs.reduce(max);
          lo = widget.mainWindowDataContainer.lows.reduce(min);
        }
        if (hi == lo) { hi += 10; lo -= 10; }

        final chartH     = maxHeight * .75 - 2 * MAIN_CHART_VERTICAL_PADDING;
        final volumeHigh = visible.map((c) => c.volume).reduce(max);

        // keep cross‑hair inside plot
        if (_crossX != null && _crossY != null) {
          _crossX = _crossX!.clamp(0.0, maxWidth);
          _crossY = _crossY!.clamp(0.0, maxHeight);
        }

        return TweenAnimationBuilder<double>(
          tween   : Tween(begin: hi, end: hi),
          duration: Duration(milliseconds: _manualHigh == null ? 300 : 0),
          builder : (_, _, __) {
            return TweenAnimationBuilder<double>(
              tween   : Tween(begin: lo, end: lo),
              duration: Duration(milliseconds: _manualHigh == null ? 300 : 0),
              builder : (_, _, __) {
                final current = (widget.showTooltip && _crossX != null)
                    ? widget.candles[min(
                        max((maxWidth - _crossX!) ~/ widget.candleWidth +
                            widget.index, 0), widget.candles.length - 1)]
                    : null;

                return Container(
                  color: widget.style.background,
                  child: Stack(
                    children: [
                      /// time labels
                      TimeRow(
                        style        : widget.style,
                        indicatorX   : widget.showTooltip ? _crossX : null,
                        candles      : widget.candles,
                        candleWidth  : widget.candleWidth,
                        indicatorTime: current?.date,
                        index        : widget.index,
                      ),

                      /// main + volume charts
                      Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Stack(children: [
                              PriceColumn(
                                style      : widget.style,
                                low        : lo,
                                high       : hi,
                                width      : constraints.maxWidth,
                                chartHeight: chartH,
                                lastCandle : widget.candles[
                                    widget.index < 0 ? 0 : widget.index],
                                onScale: (dy) {
                                  if (_manualHigh == null) {
                                    _manualHigh = hi;
                                    _manualLow  = lo;
                                  }
                                  setState(() {
                                    final d = dy / chartH *
                                        (_manualHigh! - _manualLow!);
                                    _manualHigh = _manualHigh! + d;
                                    _manualLow  = _manualLow! - d;
                                  });
                                },
                                showLastPrice: widget.showLastPrice,
                              ),
                              Row(children: [
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
                                        child: Stack(children: [
                                          MainWindowIndicatorWidget(
                                            indicatorDatas: widget
                                                .mainWindowDataContainer
                                                .indicatorComponentData,
                                            index       : widget.index,
                                            candleWidth : widget.candleWidth,
                                            low         : lo,
                                            high        : hi,
                                          ),
                                          CandleStickWidget(
                                            candles    : widget.candles,
                                            candleWidth: widget.candleWidth,
                                            index      : widget.index,
                                            high       : hi,
                                            low        : lo,
                                            bearColor  : widget.style.primaryBear,
                                            bullColor  : widget.style.primaryBull,
                                          ),
                                        ]),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: PRICE_BAR_WIDTH),
                              ]),
                            ]),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(children: [
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
                            ]),
                          ),
                          const SizedBox(height: DATE_BAR_HEIGHT),
                        ],
                      ),

                      /// cross‑hair + tooltip
                      if (widget.showTooltip && _crossY != null)
                        Positioned(
                          top: _crossY! - 10,
                          child: Row(children: [
                            DashLine(
                              length   : maxWidth,
                              color    : widget.style.borderColor,
                              direction: Axis.horizontal,
                              thickness: .5,
                            ),
                            Container(
                              color : Colors.grey.shade800,
                              width : PRICE_BAR_WIDTH,
                              height: 20,
                              alignment: Alignment.center,
                              child: Text(
                                _crossY! < maxHeight * .75
                                    ? HelperFunctions.priceToString(
                                        hi - (_crossY! -
                                                MAIN_CHART_VERTICAL_PADDING) /
                                            (maxHeight * .75 -
                                                2 * MAIN_CHART_VERTICAL_PADDING) *
                                            (hi - lo))
                                    : HelperFunctions.addMetricPrefix(
                                        HelperFunctions.getRoof(volumeHigh) *
                                            (1 -
                                                (_crossY! - maxHeight * .75 - 10) /
                                                    (maxHeight * .25 - 10))),
                                style: TextStyle(
                                  color: widget.style.secondaryTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ]),
                        ),

                      if (widget.showTooltip && _crossX != null)
                        Positioned(
                          right: (maxWidth - _crossX!) ~/
                                      widget.candleWidth *
                                      widget.candleWidth +
                                  PRICE_BAR_WIDTH,
                          child: Container(
                            width : widget.candleWidth,
                            height: maxHeight,
                            color : widget.style.mobileCandleHoverColor,
                          ),
                        ),

                      /// gesture layer
                      Padding(
                        padding: const EdgeInsets.only(right: 50, bottom: 20),
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onScaleStart: (d) =>
                              widget.onPanDown(d.localFocalPoint.dx),
                          onScaleUpdate: (d) {
                            if (d.scale == 1) {
                              widget.onHorizontalDragUpdate(d.focalPoint.dx);
                              if (_manualHigh != null) {
                                setState(() {
                                  final dy = d.focalPointDelta.dy / chartH *
                                      (_manualHigh! - _manualLow!);
                                  _manualHigh = _manualHigh! + dy;
                                  _manualLow  = _manualLow!  + dy;
                                });
                              }
                            }
                            widget.onScaleUpdate(d.scale);
                          },
                          onScaleEnd: (_) => widget.onPanEnd(),
                          onLongPressStart: widget.showTooltip
                              ? (d) => setState(() {
                                    _crossX = d.localPosition.dx;
                                    _crossY = d.localPosition.dy;
                                  })
                              : null,
                          onLongPressMoveUpdate: widget.showTooltip
                              ? (d) => setState(() {
                                    _crossX = d.localPosition.dx;
                                    _crossY = d.localPosition.dy;
                                  })
                              : null,
                          onLongPressEnd: widget.showTooltip
                              ? (_) => setState(() {
                                    _crossX = null;
                                    _crossY = null;
                                  })
                              : null,
                        ),
                      ),

                      /// indicator / OHLC bar on top
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 12),
                        child: TopPanel(
                          style          : widget.style,
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



