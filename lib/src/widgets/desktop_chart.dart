// desktop_chart.dart
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
  const DesktopChart({
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
    this.showTooltip   = true,
    this.showLastPrice = true,   // ← NEW
  });

  final Function(double)              onScaleUpdate;
  final Function(double)              onHorizontalDragUpdate;
  final double                        candleWidth;
  final List<Candle>                  candles;
  final int                           index;
  final ChartAdjust                   chartAdjust;
  final CandleSticksStyle             style;
  final void Function(double)         onPanDown;
  final VoidCallback                  onPanEnd;
  final VoidCallback                  onReachEnd;
  final MainWindowDataContainer       mainWindowDataContainer;
  final void Function(String)?        onRemoveIndicator;

  /// Hide / show cross‑hair & hover tooltip
  final bool showTooltip;

  /// Hide / show coloured last‑price chip on the RHS
  final bool showLastPrice;

  @override
  State<DesktopChart> createState() => _DesktopChartState();
}

class _DesktopChartState extends State<DesktopChart> {
  double? _mouseX;
  double? _mouseY;

  bool  _isDragging   = false;
  bool  _hoverVisible = true;        // disables while panning
  double? _manualHi;
  double? _manualLo;

  // ═══════════════════ Pointer helpers ═══════════════════════════
  void _handleExit(PointerEvent _)   => setState(() { _mouseX = _mouseY = null; });
  void _handleHover(PointerEvent e) {
    if (!widget.showTooltip) return;
    setState(() {
      _mouseX = e.localPosition.dx;
      _mouseY = e.localPosition.dy;
    });
  }

  // ═══════════════════  Build  ═══════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final maxW = c.maxWidth  - PRICE_BAR_WIDTH;
      final maxH = c.maxHeight - DATE_BAR_HEIGHT;

      final start = max(widget.index, 0);
      final end   = min(
        maxW ~/ widget.candleWidth + widget.index,
        widget.candles.length - 1,
      );

      if (end == widget.candles.length - 1) Future(widget.onReachEnd);

      final visible = widget.candles.getRange(start, end + 1).toList();

      // ── price range
      double hi, lo;
      if (_manualHi != null) {
        hi = _manualHi!; lo = _manualLo!;
      } else if (widget.chartAdjust == ChartAdjust.visibleRange) {
        hi = widget.mainWindowDataContainer.highs
               .getRange(start, end + 1).reduce(max);
        lo = widget.mainWindowDataContainer.lows
               .getRange(start, end + 1).reduce(min);
      } else {
        hi = widget.mainWindowDataContainer.highs.reduce(max);
        lo = widget.mainWindowDataContainer.lows .reduce(min);
      }
      if (hi == lo) { hi += 10; lo -= 10; }

      final chartH  = maxH * .75 - 2 * MAIN_CHART_VERTICAL_PADDING;
      final volHi   = visible.map((e) => e.volume).reduce(max);

      final hoverOK = widget.showTooltip && _hoverVisible;
      final candleAtCursor = hoverOK && _mouseX != null
          ? widget.candles[min(
              max((maxW - _mouseX!) ~/ widget.candleWidth + widget.index, 0),
              widget.candles.length - 1,
            )]
          : null;

      return Container(
        color: widget.style.background,
        child: Listener(
          onPointerSignal: (s) {
            if (s is PointerScrollEvent) widget.onScaleUpdate(-s.scrollDelta.dy);
          },
          child: MouseRegion(
            cursor: _isDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.precise,
            onHover: _handleHover,
            onExit : _handleExit,
            child  : GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanDown: (d) {
                widget.onPanDown(d.localPosition.dx);
                setState(() { _isDragging = true; _hoverVisible = false; });
              },
              onPanUpdate: (d) {
                if (widget.showTooltip) {
                  _mouseX = d.localPosition.dx;
                  _mouseY = d.localPosition.dy;
                }
                widget.onHorizontalDragUpdate(d.localPosition.dx);

                if (_manualHi != null) {
                  final delta = d.delta.dy / chartH * (_manualHi! - _manualLo!);
                  setState(() {
                    _manualHi = _manualHi! + delta;
                    _manualLo = _manualLo! + delta;
                  });
                }
              },
              onPanEnd: (_) {
                widget.onPanEnd();
                setState(() => _isDragging = false);
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() => _hoverVisible = true);
                });
              },
              child: RepaintBoundary(
                child: _layers(
                  context, maxW, maxH, chartH,
                  hi, lo, volHi, candleAtCursor,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ═══════════════════  stacked layers ═══════════════════════════
  Widget _layers(
    BuildContext ctx,
    double maxW,
    double maxH,
    double chartH,
    double hi,
    double lo,
    double volHi,
    Candle? current,
  ) {
    final hover = widget.showTooltip && _hoverVisible;

    return Stack(children: [
      // time axis
      TimeRow(
        style         : widget.style,
        indicatorX    : hover ? _mouseX : null,
        candles       : widget.candles,
        candleWidth   : widget.candleWidth,
        indicatorTime : current?.date,
        index         : widget.index,
      ),

      // main + volume charts
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
                _manualHi ??= hi;
                _manualLo ??= lo;
                setState(() {
                  final d = dy / chartH * (_manualHi! - _manualLo!);
                  _manualHi = _manualHi! + d;
                  _manualLo = _manualLo! - d;
                });
              },
              showLastPrice: widget.showLastPrice,          // ← NEW
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
                        indicatorDatas: widget
                            .mainWindowDataContainer.indicatorComponentData,
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
      ]),

      // horizontal hover & price tooltip
      if (hover && _mouseY != null)
        Positioned(
          top: _mouseY! - 10,
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
              alignment: Alignment.center,
              child: Text(
                _mouseY! < maxH * .75
                    ? HelperFunctions.priceToString(
                        hi -
                            (_mouseY! - MAIN_CHART_VERTICAL_PADDING) /
                                (maxH * .75 - 2 * MAIN_CHART_VERTICAL_PADDING) *
                                (hi - lo),
                      )
                    : HelperFunctions.addMetricPrefix(
                        HelperFunctions.getRoof(volHi) *
                            (1 -
                                (_mouseY! - maxH * .75 - 10) /
                                    (maxH * .25 - 10)),
                      ),
                style: TextStyle(
                    color: widget.style.secondaryTextColor, fontSize: 12),
              ),
            ),
          ]),
        ),

      // vertical hover line
      if (hover && _mouseX != null)
        Positioned(
          left: _mouseX,
          child: DashLine(
            length   : ctx.size!.height - 20,
            color    : widget.style.borderColor,
            direction: Axis.vertical,
            thickness: .5,
          ),
        ),

      // top info panel
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
