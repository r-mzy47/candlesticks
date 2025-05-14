import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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

import '../models/candle.dart';
import 'dash_line.dart';

class DesktopChart extends StatefulWidget {
  final Function(double)              onScaleUpdate;
  final Function(double)              onHorizontalDragUpdate;
  final double                        candleWidth;
  final List<Candle>                  candles;
  final int                           index;
  final ChartAdjust                   chartAdjust;
  final CandleSticksStyle             style;
  final void Function(double)         onPanDown;
  final void Function()               onPanEnd;
  final Function()                    onReachEnd;
  final MainWindowDataContainer       mainWindowDataContainer;
  final void Function(String)?        onRemoveIndicator;

  /// ⬇︎ NEW – hide tooltip / cross‑hair when `false`
  final bool showTooltip;

  DesktopChart({
    super.key,
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
    this.showTooltip = true,
  });

  @override
  State<DesktopChart> createState() => _DesktopChartState();
}

class _DesktopChartState extends State<DesktopChart> {
  double? mouseX;
  double? mouseY;

  bool    isDragging         = false;
  bool    hoverVisible       = true;          // hidden while dragging
  double? manualScaleHigh;
  double? manualScaleLow;

  // ───────────────────────── helpers ──────────────────────────
  void _onExit(PointerEvent _) =>
      setState(() { mouseX = mouseY = null; });

  void _onHover(PointerEvent e) {
    if (!widget.showTooltip) return;
    setState(() {
      mouseX = e.localPosition.dx;
      mouseY = e.localPosition.dy;
    });
  }

  // ───────────────────────── build ────────────────────────────
  @override
  Widget build(BuildContext ctx) {
    return LayoutBuilder(builder: (_, c) {
      final maxW = c.maxWidth  - PRICE_BAR_WIDTH;
      final maxH = c.maxHeight - DATE_BAR_HEIGHT;

      final start = max(widget.index, 0);
      final end   = min(maxW ~/ widget.candleWidth + widget.index,
                        widget.candles.length - 1);

      if (end == widget.candles.length - 1) Future(widget.onReachEnd);

      final visible = widget.candles.getRange(start, end + 1).toList();

      // ── price scales ───────────────────────────────────────
      double hi, lo;
      if (manualScaleHigh != null) {
        hi = manualScaleHigh!; lo = manualScaleLow!;
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

      final chartH   = maxH * .75 - 2 * MAIN_CHART_VERTICAL_PADDING;
      final volHi    = visible.map((e) => e.volume).reduce(max);
      final candleAtCursor = (widget.showTooltip && mouseX != null)
          ? widget.candles[min(max((maxW - mouseX!) ~/ widget.candleWidth +
                                   widget.index, 0),
                               widget.candles.length - 1)]
          : null;

      // ── UI ────────────────────────────────────────────────
      return Container(
        color: widget.style.background,
        child: Listener(
          onPointerSignal: (s) {
            if (s is PointerScrollEvent) widget.onScaleUpdate(-s.scrollDelta.dy);
          },
          child: MouseRegion(
            cursor : isDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.precise,
            onHover: _onHover,
            onExit : _onExit,
            child  : GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanDown: (d) {
                widget.onPanDown(d.localPosition.dx);
                setState(() { isDragging = true; hoverVisible = false; });
              },
              onPanUpdate: (d) {
                if (widget.showTooltip) {
                  mouseX = d.localPosition.dx;
                  mouseY = d.localPosition.dy;
                }
                widget.onHorizontalDragUpdate(d.localPosition.dx);
                if (manualScaleHigh != null) {
                  final delta = d.delta.dy / chartH * (manualScaleHigh! - manualScaleLow!);
                  setState(() {
                    manualScaleHigh = manualScaleHigh! + delta;
                    manualScaleLow  = manualScaleLow! + delta;
                  });
                }
              },
              onPanEnd: (_) {
                widget.onPanEnd();
                setState(() => isDragging = false);
                Future.delayed(const Duration(milliseconds: 300),
                    () => mounted ? setState(() => hoverVisible = true) : null);
              },
              child: RepaintBoundary(
                child: _buildChart(ctx, maxW, maxH, chartH,
                                   hi, lo, volHi, candleAtCursor),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ───────────────── helper to build chart layers ─────────────
  Widget _buildChart(
    BuildContext ctx,
    double maxW,
    double maxH,
    double chartH,
    double hi,
    double lo,
    double volHi,
    Candle?  current,
  ) {
    final hover = widget.showTooltip && hoverVisible;
    return Stack(children: [
      // time row
      TimeRow(
        style         : widget.style,
        indicatorX    : hover ? mouseX : null,
        candles       : widget.candles,
        candleWidth   : widget.candleWidth,
        indicatorTime : current?.date,
        index         : widget.index,
      ),

      // main chart & volume
      Column(children: [
        Expanded(
          flex: 3,
          child: Stack(children: [
            PriceColumn(
              style      : widget.style,
              low        : lo,
              high       : hi,
              width      : ctx.size!.width,
              chartHeight: chartH,
              lastCandle : widget.candles[widget.index < 0 ? 0 : widget.index],
              onScale    : (dy) {
                manualScaleHigh ??= hi;
                manualScaleLow  ??= lo;
                setState(() {
                  final d = dy / chartH * (manualScaleHigh! - manualScaleLow!);
                  manualScaleHigh = manualScaleHigh! + d;
                  manualScaleLow  = manualScaleLow! - d;
                });
              },
            ),
            Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: widget.style.borderColor, width: 1),
                    ),
                  ),
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 300),
                    padding : const EdgeInsets.symmetric(
                        vertical: MAIN_CHART_VERTICAL_PADDING),
                    child: Stack(children: [
                      MainWindowIndicatorWidget(
                        indicatorDatas: widget.mainWindowDataContainer
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
                    right: BorderSide(color: widget.style.borderColor, width: 1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: VolumeWidget(
                    candles   : widget.candles,
                    barWidth  : widget.candleWidth,
                    index     : widget.index,
                    high      : HelperFunctions.getRoof(volHi),
                    bearColor : widget.style.secondaryBear,
                    bullColor : widget.style.secondaryBull,
                  ),
                ),
              ),
            ),
            SizedBox(
              width : PRICE_BAR_WIDTH,
              child : Column(
                children: [
                  SizedBox(
                    height: DATE_BAR_HEIGHT,
                    child : Center(
                      child: Text(
                        "-${HelperFunctions.addMetricPrefix(HelperFunctions.getRoof(volHi))}",
                        style: TextStyle(color: widget.style.borderColor, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: DATE_BAR_HEIGHT),
      ]),

      // horizontal price tooltip
      if (hover && mouseY != null)
        Positioned(
          top: mouseY! - 10,
          child: Row(children: [
            DashLine(
              length   : maxW,
              color    : widget.style.borderColor,
              direction: Axis.horizontal,
              thickness: .5,
            ),
            Container(
              color : Colors.grey.shade800,
              width : PRICE_BAR_WIDTH,
              height: 20,
              child : Center(
                child: Text(
                  mouseY! < maxH * .75
                      ? HelperFunctions.priceToString(
                          hi -
                              (mouseY! - MAIN_CHART_VERTICAL_PADDING) /
                                  (maxH * .75 -
                                      2 * MAIN_CHART_VERTICAL_PADDING) *
                                  (hi - lo),
                        )
                      : HelperFunctions.addMetricPrefix(
                          HelperFunctions.getRoof(volHi) *
                              (1 -
                                  (mouseY! - maxH * .75 - 10) /
                                      (maxH * .25 - 10)),
                        ),
                  style: TextStyle(
                      color: widget.style.secondaryTextColor, fontSize: 12),
                ),
              ),
            ),
          ]),
        ),

      // vertical cross‑hair
      if (hover && mouseX != null)
        Positioned(
          left: mouseX,
          child: DashLine(
            length   : ctx.size!.height - 20,
            color    : widget.style.borderColor,
            direction: Axis.vertical,
            thickness: .5,
          ),
        ),

      // top info bar
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child : TopPanel(
          style                 : widget.style,
          onRemoveIndicator     : widget.onRemoveIndicator,
          currentCandle         : current,
          indicators            : widget.mainWindowDataContainer.indicators,
          toggleIndicatorVisibility: (name) {
            setState(() {
              widget.mainWindowDataContainer.toggleIndicatorVisibility(name);
            });
          },
          unvisibleIndicators   : widget.mainWindowDataContainer.unvisibleIndicators,
        ),
      ),
    ]);
  }
}
