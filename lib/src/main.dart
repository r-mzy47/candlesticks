import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:candlesticks/src/widgets/chart_copmoser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final isDesktopLike = kIsWeb ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;

enum ChartAdjust {
  /// Will adjust chart size by max and min value from visible area
  visibleRange,

  /// Will adjust chart size by max and min value from the whole data
  fullRange
}

/// StatefulWidget that holds Chart's State (index of
/// current position and candles width).
class Candlesticks extends StatefulWidget {
  /// The arrangement of the array should be such that
  /// the newest item is in position 0
  final List<Candle> candles;

  /// This callback calls when the last candle gets visible
  final Future<void> Function()? onLoadMoreCandles;

  /// How chart price range will be adjusted when moving chart
  final ChartAdjust chartAdjust;

  /// Custom loading widget
  final Widget? loadingWidget;

  final CandleSticksStyle? style;

  final CandlesticksController? controller;

  const Candlesticks({
    Key? key,
    required this.candles,
    this.onLoadMoreCandles,
    this.chartAdjust = ChartAdjust.visibleRange,
    this.loadingWidget,
    this.controller,
    this.style,
  })  : assert(candles.length == 0 || candles.length > 1,
            "Please provide at least 2 candles"),
        super(key: key);

  @override
  _CandlesticksState createState() => _CandlesticksState();
}

class _CandlesticksState extends State<Candlesticks> {
  late final CandlesticksController _internalController;

  /// true when widget.onLoadMoreCandles is fetching new candles.
  bool isCallingLoadMore = false;
  CandlesticksController get _controller =>
      widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = CandlesticksController();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        (Theme.of(context).brightness == Brightness.dark
            ? CandleSticksStyle.dark()
            : CandleSticksStyle.light());
    return CandleSticksStyleProvider(
      style: style,
      child: (widget.candles.length == 0)
          ? Center(
              child: widget.loadingWidget ??
                  CircularProgressIndicator(color: style.loadingColor),
            )
          : ChartComposer(
              controller: _controller,
              chartAdjust: widget.chartAdjust,
              onReachEnd: () {
                if (isCallingLoadMore == false &&
                    widget.onLoadMoreCandles != null) {
                  isCallingLoadMore = true;
                  widget.onLoadMoreCandles!().then((_) {
                    isCallingLoadMore = false;
                  });
                }
              },
              candles: widget.candles,
            ),
    );
  }
}
