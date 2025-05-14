import 'dart:io' show Platform;
import 'dart:math';

import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/models/main_window_indicator.dart';
import 'package:candlesticks/src/widgets/desktop_chart.dart';
import 'package:candlesticks/src/widgets/mobile_chart.dart';
import 'package:candlesticks/src/widgets/toolbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';   // ListEquality

// ──────────────────────────────────────────────────────────────
//  ChartAdjust
// ──────────────────────────────────────────────────────────────
enum ChartAdjust { visibleRange, fullRange }

// ──────────────────────────────────────────────────────────────
//  Candlesticks widget
// ──────────────────────────────────────────────────────────────
class Candlesticks extends StatefulWidget {
  /// Candles oldest → newest
  final List<Candle> candles;

  /// Flip so index 0 is the *newest* bar
  final bool reversed;

  /// Starting candle width (2–20 px)
  final double initialCandleWidth;

  /// Disable / enable long‑press tool‑tip & cross‑hair
  final bool showTooltip;                        // ← NEW

  /// Callback when right edge is reached
  final Future<void> Function()? onLoadMoreCandles;

  /// Extra toolbar buttons
  final List<ToolBarAction> actions;

  /// Indicators
  final List<Indicator>? indicators;
  final void Function(String)? onRemoveIndicator;

  /// Chart scaling mode
  final ChartAdjust chartAdjust;

  /// Show “+ / –” buttons
  final bool displayZoomActions;

  /// Custom loader
  final Widget? loadingWidget;

  /// Style override
  final CandleSticksStyle? style;

  Candlesticks({
    Key? key,
    required this.candles,
    this.reversed            = false,
    this.initialCandleWidth  = 6,
    this.showTooltip         = true,            // ← NEW
    this.onLoadMoreCandles,
    this.actions             = const [],
    this.chartAdjust         = ChartAdjust.visibleRange,
    this.displayZoomActions  = true,
    this.loadingWidget,
    this.indicators,
    this.onRemoveIndicator,
    this.style,
  })  : assert(candles.isEmpty || candles.length > 1,
            'Please provide at least 2 candles'),
        super(key: key);

  @override
  State<Candlesticks> createState() => _CandlesticksState();
}

// ──────────────────────────────────────────────────────────────
//  State
// ──────────────────────────────────────────────────────────────
class _CandlesticksState extends State<Candlesticks> {
  // data mapping
  List<Candle> get _candles =>
      widget.reversed ? widget.candles.reversed.toList() : widget.candles;

  // scroll / zoom
  int    index       = -10;
  double lastX       = 0;
  int    lastIndex   = -10;
  double candleWidth = 6;

  bool isCallingLoadMore = false;

  // indicators
  MainWindowDataContainer? mainWindowDataContainer;

  // ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    candleWidth = widget.initialCandleWidth.clamp(2, 20);
    if (_candles.isNotEmpty) {
      mainWindowDataContainer =
          MainWindowDataContainer(widget.indicators ?? [], _candles);
    }
  }

  @override
  void didUpdateWidget(covariant Candlesticks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_candles.isEmpty) return;

    mainWindowDataContainer ??=
        MainWindowDataContainer(widget.indicators ?? [], _candles);

    final newIndis = widget.indicators ?? [];
    final oldIndis = oldWidget.indicators ?? [];

    if (newIndis.length != oldIndis.length ||
        !const ListEquality().equals(newIndis, oldIndis)) {
      mainWindowDataContainer =
          MainWindowDataContainer(newIndis, _candles);
      return;
    }

    try {
      mainWindowDataContainer!.tickUpdate(_candles);
    } catch (_) {
      mainWindowDataContainer =
          MainWindowDataContainer(newIndis, _candles);
    }
  }

  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        (Theme.of(context).brightness == Brightness.dark
            ? CandleSticksStyle.dark()
            : CandleSticksStyle.light());

    return Column(
      children: [
        if (widget.displayZoomActions || widget.actions.isNotEmpty)
          ToolBar(
            color: style.toolBarColor,
            children: [
              if (widget.displayZoomActions) ...[
                ToolBarAction(
                  onPressed: () =>
                      setState(() => candleWidth = max(candleWidth - 2, 2)),
                  child: Icon(Icons.remove, color: style.borderColor),
                ),
                ToolBarAction(
                  onPressed: () =>
                      setState(() => candleWidth = min(candleWidth + 2, 20)),
                  child: Icon(Icons.add, color: style.borderColor),
                ),
              ],
              ...widget.actions,
            ],
          ),
        if (_candles.isEmpty || mainWindowDataContainer == null)
          Expanded(
            child: Center(
              child: widget.loadingWidget ??
                  CircularProgressIndicator(color: style.loadingColor),
            ),
          )
        else
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 6, end: candleWidth),
              duration: const Duration(milliseconds: 120),
              builder: (_, width, __) => _chart(style, width),
            ),
          ),
      ],
    );
  }

  Widget _chart(CandleSticksStyle style, double width) {
    final commonProps = {
      'style'                  : style,
      'onRemoveIndicator'      : widget.onRemoveIndicator,
      'mainWindowDataContainer': mainWindowDataContainer!,
      'chartAdjust'            : widget.chartAdjust,
      'onScaleUpdate'          : _handleScale,
      'onPanEnd'               : () => lastIndex = index,
      'onHorizontalDragUpdate' : _handleHorizontalDrag,
      'onPanDown'              : _handlePanDown,
      'onReachEnd'             : _handleReachEnd,
      'candleWidth'            : width,
      'candles'                : _candles,
      'index'                  : index,
      'showTooltip'            : widget.showTooltip,   // ← NEW
    };

    final chart = (kIsWeb ||
            Platform.isMacOS ||
            Platform.isWindows ||
            Platform.isLinux)
        ? DesktopChart.fromMap(commonProps)
        : MobileChart .fromMap(commonProps);

    return chart;
  }

  // ── gestures ────────────────────────────────────────────────
  void _handleScale(double scale) {
    scale = scale.clamp(0.90, 1.10);
    setState(() => candleWidth = (candleWidth * scale).clamp(2, 20));
  }

  void _handleHorizontalDrag(double x) {
    setState(() {
      final delta = x - lastX;
      index =
          (lastIndex + delta ~/ candleWidth).clamp(-10, _candles.length - 1);
    });
  }

  void _handlePanDown(double value) {
    lastX = value;
    lastIndex = index;
  }

  void _handleReachEnd() {
    if (!isCallingLoadMore && widget.onLoadMoreCandles != null) {
      isCallingLoadMore = true;
      widget.onLoadMoreCandles!().whenComplete(() {
        isCallingLoadMore = false;
      });
    }
  }
}

