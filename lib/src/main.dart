import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:candlesticks/src/widgets/chart_composer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final isDesktopLike = kIsWeb ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;

enum ChartAdjust {
  /// Will adjust chart size by max and min value from visible area.
  visibleRange,

  /// Will adjust chart size by max and min value from the whole data.
  fullRange
}

/// StatefulWidget that holds chart state.
class Candlesticks extends StatefulWidget {
  /// The arrangement of the array should be such that
  /// the newest item is in position 0.
  final List<Candle> candles;

  /// Called when the chart is close to the oldest loaded candle.
  final Future<void> Function()? onLoadMoreCandles;

  /// How chart price range will be adjusted when moving chart.
  final ChartAdjust chartAdjust;

  /// Custom loading widget.
  final Widget? loadingWidget;

  final CandleSticksStyle? style;

  final CandlesticksController? controller;

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
                    color: style.loadingColor,
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
