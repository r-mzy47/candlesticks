import 'dart:math';
import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/models/main_window_indicator.dart';
import 'package:candlesticks/src/widgets/mobile_chart.dart';
import 'package:candlesticks/src/widgets/desktop_chart.dart';
import 'package:candlesticks/src/widgets/toolbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

enum ChartAdjust {
  /// Adjust chart size by max/min of **visible** candles
  visibleRange,

  /// Adjust chart size by max/min of the **whole** series
  fullRange,
}

/// Stateful widget that owns chart state (scroll index + candle width).
class Candlesticks extends StatefulWidget {
  /// Candle list; default expectation is **oldest → newest**.
  ///
  /// If your list is newest‑first, just set `reversed:true`.
  final List<Candle> candles;

  /// Flip the array once so the library sees “newest at 0”.
  final bool reversed;

  /// Called when the last candle becomes visible.
  final Future<void> Function()? onLoadMoreCandles;

  /// Extra buttons for the top toolbar.
  final List<ToolBarAction> actions;

  /// Indicators to draw.
  final List<Indicator>? indicators;

  /// Fires when user clicks the X on an indicator label.
  final void Function(String)? onRemoveIndicator;

  /// How price range is calculated while panning.
  final ChartAdjust chartAdjust;

  /// Show ± zoom buttons in the toolbar.
  final bool displayZoomActions;

  /// Replace the default loader.
  final Widget? loadingWidget;

  /// Customise colours & fonts.
  final CandleSticksStyle? style;

  const Candlesticks({
    Key? key,
    required this.candles,
    this.reversed = false,                        // ← NEW
    this.onLoadMoreCandles,
    this.actions = const [],
    this.chartAdjust = ChartAdjust.visibleRange,
    this.displayZoomActions = true,
    this.loadingWidget,
    this.indicators,
    this.onRemoveIndicator,
    this.style,
  })  : assert(candles.isEmpty || candles.length > 1,
            "Please provide at least 2 candles"),
        super(key: key);

  @override
  _CandlesticksState createState() => _CandlesticksState();
}

class _CandlesticksState extends State<Candlesticks> {
  // ───────── internal helpers ────────────────────────────────────────────────

  /// Effective candle list in the order the library expects
  /// (index 0 = newest). Flipped once if [widget.reversed] is true.
  List<Candle> get _candles =>
      widget.reversed ? widget.candles.reversed.toList() : widget.candles;

  // ───────── mutable state ──────────────────────────────────────────────────
  int index = -10;            // scroll offset (newest index displayed)
  double lastX = 0;           // drag tracking
  int lastIndex = -10;

  double candleWidth = 6;     // 2 … 20 px

  bool isCallingLoadMore = false;

  MainWindowDataContainer? mainWindowDataContainer;

  // ───────── lifecycle ──────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    if (_candles.isEmpty) return;

    mainWindowDataContainer ??=
        MainWindowDataContainer(widget.indicators ?? [], _candles);
  }

  @override
  void didUpdateWidget(covariant Candlesticks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_candles.isEmpty) return;

    if (mainWindowDataContainer == null) {
      mainWindowDataContainer =
          MainWindowDataContainer(widget.indicators ?? [], _candles);
      return;
    }

    final currentIndicators = widget.indicators ?? [];
    final oldIndicators = oldWidget.indicators ?? [];

    // Re‑create container if indicator list changed
    if (currentIndicators.length != oldIndicators.length ||
        !ListEquality().equals(currentIndicators, oldIndicators)) {
      mainWindowDataContainer =
          MainWindowDataContainer(currentIndicators, _candles);
      return;
    }

    // Otherwise just tick‑update
    try {
      mainWindowDataContainer!.tickUpdate(_candles);
    } catch (_) {
      mainWindowDataContainer =
          MainWindowDataContainer(currentIndicators, _candles);
    }
  }

  // ───────── UI ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        (Theme.of(context).brightness == Brightness.dark
            ? const CandleSticksStyle.dark()
            : const CandleSticksStyle.light());

    return Column(
      children: [
        if (widget.displayZoomActions || widget.actions.isNotEmpty) ...[
          ToolBar(
            color: style.toolBarColor,
            children: [
              if (widget.displayZoomActions) ...[
                ToolBarAction(
                  onPressed: () {
                    setState(() {
                      candleWidth = max(candleWidth - 2, 2);
                    });
                  },
                  child: Icon(Icons.remove, color: style.borderColor),
                ),
                ToolBarAction(
                  onPressed: () {
                    setState(() {
                      candleWidth = min(candleWidth + 2, 20);
                    });
                  },
                  child: Icon(Icons.add, color: style.borderColor),
                ),
              ],
              ...widget.actions,
            ],
          ),
        ],

        // ── chart or loader ────────────────────────────────────────────────
        if (_candles.isEmpty || mainWindowDataContainer == null)
          Expanded(
            child: Center(
              child: widget.loadingWidget ??
                  CircularProgressIndicator(color: style.loadingColor),
            ),
          )
        else
          Expanded(
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 6, end: candleWidth),
              duration: const Duration(milliseconds: 120),
              builder: (_, double width, __) {
                final chart = (kIsWeb ||
                        Platform.isMacOS ||
                        Platform.isWindows ||
                        Platform.isLinux)
                    ? DesktopChart(
                        style: style,
                        onRemoveIndicator: widget.onRemoveIndicator,
                        mainWindowDataContainer: mainWindowDataContainer!,
                        chartAdjust: widget.chartAdjust,
                        onScaleUpdate: _handleScale,
                        onPanEnd: () => lastIndex = index,
                        onHorizontalDragUpdate: _handleHorizontalDrag,
                        onPanDown: _handlePanDown,
                        onReachEnd: _handleReachEnd,
                        candleWidth: width,
                        candles: _candles,
                        index: index,
                      )
                    : MobileChart(
                        style: style,
                        onRemoveIndicator: widget.onRemoveIndicator,
                        mainWindowDataContainer: mainWindowDataContainer!,
                        chartAdjust: widget.chartAdjust,
                        onScaleUpdate: _handleScale,
                        onPanEnd: () => lastIndex = index,
                        onHorizontalDragUpdate: _handleHorizontalDrag,
                        onPanDown: _handlePanDown,
                        onReachEnd: _handleReachEnd,
                        candleWidth: width,
                        candles: _candles,
                        index: index,
                      );
                return chart;
              },
            ),
          ),
      ],
    );
  }

  // ───────── gesture helpers ───────────────────────────────────────────────
  void _handleScale(double scale) {
    scale = scale.clamp(0.90, 1.10);
    setState(() {
      candleWidth = (candleWidth * scale).clamp(2, 20);
    });
  }

  void _handleHorizontalDrag(double x) {
    setState(() {
      final delta = x - lastX;
      index = (lastIndex + delta ~/ candleWidth)
          .clamp(-10, _candles.length - 1);
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
