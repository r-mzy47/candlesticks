import 'dart:math';
import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/models/main_window_indicator.dart';
import 'package:candlesticks/src/widgets/mobile_chart.dart';
import 'package:candlesticks/src/widgets/desktop_chart.dart';
import 'package:candlesticks/src/widgets/toolbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:collection/collection.dart';           // ✱ FIX

enum ChartAdjust { visibleRange, fullRange }

class Candlesticks extends StatefulWidget {
  final List<Candle> candles;
  final bool reversed;
  final Future<void> Function()? onLoadMoreCandles;
  final List<ToolBarAction> actions;
  final List<Indicator>? indicators;
  final void Function(String)? onRemoveIndicator;
  final ChartAdjust chartAdjust;
  final bool displayZoomActions;
  final Widget? loadingWidget;
  final CandleSticksStyle? style;

  // ✱ FIX: remove `const` — assert uses runtime values
  Candlesticks({
    Key? key,
    required this.candles,
    this.reversed = false,
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
  List<Candle> get _candles =>
      widget.reversed ? widget.candles.reversed.toList() : widget.candles;

  int index = -10;
  double lastX = 0;
  int lastIndex = -10;
  double candleWidth = 6;
  bool isCallingLoadMore = false;
  MainWindowDataContainer? mainWindowDataContainer;

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

    if (currentIndicators.length != oldIndicators.length ||
        !const ListEquality()
            .equals(currentIndicators, oldIndicators)) {      // ✱ FIX
      mainWindowDataContainer =
          MainWindowDataContainer(currentIndicators, _candles);
      return;
    }

    try {
      mainWindowDataContainer!.tickUpdate(_candles);
    } catch (_) {
      mainWindowDataContainer =
          MainWindowDataContainer(currentIndicators, _candles);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        (Theme.of(context).brightness == Brightness.dark
            ? CandleSticksStyle.dark()      // ✱ FIX: no `const`
            : CandleSticksStyle.light());    // ✱ FIX

    return Column(
      children: [
        if (widget.displayZoomActions || widget.actions.isNotEmpty) ...[
          ToolBar(
            color: style.toolBarColor,
            children: [
              if (widget.displayZoomActions) ...[
                ToolBarAction(
                  onPressed: () {
                    setState(() => candleWidth = max(candleWidth - 2, 2));
                  },
                  child: Icon(Icons.remove, color: style.borderColor),
                ),
                ToolBarAction(
                  onPressed: () {
                    setState(() => candleWidth = min(candleWidth + 2, 20));
                  },
                  child: Icon(Icons.add, color: style.borderColor),
                ),
              ],
              ...widget.actions,
            ],
          ),
        ],
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

  // ── gesture helpers ────────────────────────────────────────────────────
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
