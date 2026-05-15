import 'package:candlesticks/candlesticks.dart';

import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:candlesticks/src/widgets/chart_composer.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final isDesktopLike = kIsWeb ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;

/// Defines how the visible price range of the chart is calculated.
enum ChartAdjust {
  /// Calculates the chart price range from the currently visible candles.
  ///
  /// This keeps the chart vertically focused on the visible data while the user
  /// scrolls.
  visibleRange,

  /// Calculates the chart price range from the full candle list.
  ///
  /// This keeps the vertical scale stable while the user scrolls, but it may
  /// make smaller visible price movements harder to see.
  fullRange,
}

/// A Flutter candlestick chart widget.
///
/// The [Candlesticks] widget displays OHLCV candle data with price and volume
/// areas. It supports scrolling, zooming, custom styles, programmatic control
/// through [CandlesticksController], and lazy loading older candles with
/// [onLoadMoreCandles].
///
/// The [candles] list must be ordered from newest to oldest. The newest candle
/// should be at index `0`.
///
/// Example:
///
/// ```dart
/// final controller = CandlesticksController();
///
/// Candlesticks(
///   candles: candles,
///   controller: controller,
///   chartAdjust: ChartAdjust.visibleRange,
///   onLoadMoreCandles: () async {
///     final olderCandles = await fetchOlderCandles();
///     setState(() {
///       candles.addAll(olderCandles);
///     });
///   },
/// )
/// ```
class Candlesticks extends StatefulWidget {
  /// Candle data displayed by the chart.
  ///
  /// The list must be ordered from newest to oldest. The newest candle should
  /// be at index `0`.
  ///
  /// The list can be empty to show [loadingWidget]. Otherwise, it must contain
  /// at least two candles.
  final List<Candle> candles;

  /// Called when the chart scroll position is close to the oldest loaded candle.
  ///
  /// Use this callback to load older candles and append them to [candles].
  ///
  /// The widget prevents overlapping calls while a previous load operation is
  /// still running.
  final Future<void> Function()? onLoadMoreCandles;

  /// Defines how the chart price range is calculated while scrolling.
  final ChartAdjust chartAdjust;

  /// Widget displayed when [candles] is empty.
  ///
  /// If this is null, a [CircularProgressIndicator] using the style loading
  /// color is displayed.
  final Widget? loadingWidget;

  /// Visual style used by the chart.
  ///
  /// If this is null, the chart uses [CandleSticksStyle.dark] or
  /// [CandleSticksStyle.light] based on the current [ThemeData.brightness].
  final CandleSticksStyle? style;

  /// Controller used to read or update the chart viewport.
  ///
  /// If this is null, the widget creates and manages an internal controller.
  final CandlesticksController? controller;

  /// Creates a candlestick chart.
  ///
  /// The [candles] list can be empty while loading. When it is not empty, it
  /// must contain at least two candles.
  const Candlesticks({
    super.key,
    required this.candles,
    this.onLoadMoreCandles,
    this.chartAdjust = ChartAdjust.visibleRange,
    this.loadingWidget,
    this.controller,
    this.style,
  }) : assert(
          candles.length == 0 || candles.length > 1,
          'Please provide at least 2 candles',
        );

  @override
  State<Candlesticks> createState() => _CandlesticksState();
}

class _CandlesticksState extends State<Candlesticks> {
  late final CandlesticksController _internalController;

  bool _isLoadingMoreCandles = false;

  CandlesticksController get _controller {
    return widget.controller ?? _internalController;
  }

  @override
  void initState() {
    super.initState();
    _internalController = CandlesticksController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant Candlesticks oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldController = oldWidget.controller ?? _internalController;
    final newController = widget.controller ?? _internalController;

    if (!identical(oldController, newController)) {
      oldController.removeListener(_onControllerChanged);
      newController.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _internalController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!_controller.isNearEnd) return;

    _loadMoreCandles();
  }

  Future<void> _loadMoreCandles() async {
    final onLoadMoreCandles = widget.onLoadMoreCandles;

    if (_isLoadingMoreCandles) return;
    if (onLoadMoreCandles == null) return;

    _isLoadingMoreCandles = true;

    try {
      await onLoadMoreCandles();
    } finally {
      _isLoadingMoreCandles = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        (Theme.of(context).brightness == Brightness.dark
            ? CandleSticksStyle.dark()
            : CandleSticksStyle.light());

    return CandleSticksStyleProvider(
      style: style,
      child: widget.candles.isEmpty
          ? Center(
              child: widget.loadingWidget ??
                  CircularProgressIndicator(
                    color: style.loadingIndicatorColor,
                  ),
            )
          : ChartComposer(
              controller: _controller,
              chartAdjust: widget.chartAdjust,
              candles: widget.candles,
            ),
    );
  }
}
