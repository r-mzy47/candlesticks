import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/widgets/chart_copmoser.dart';
import 'package:candlesticks/src/widgets/toolbar.dart';
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

  /// List of buttons you what to add on top tool bar
  final List<ToolBarAction> actions;

  /// How chart price range will be adjusted when moving chart
  final ChartAdjust chartAdjust;

  /// Will zoom buttons be displayed in toolbar
  final bool displayZoomActions;

  /// Custom loading widget
  final Widget? loadingWidget;

  final CandleSticksStyle? style;

  final CandlesticksController? controller;

  const Candlesticks({
    Key? key,
    required this.candles,
    this.onLoadMoreCandles,
    this.actions = const [],
    this.chartAdjust = ChartAdjust.visibleRange,
    this.displayZoomActions = true,
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
    return Column(
      children: [
        if (widget.displayZoomActions == true || widget.actions.isNotEmpty) ...[
          ToolBar(
            color: style.toolBarColor,
            border: Border.symmetric(
              horizontal: BorderSide(
                color: style.borderColor,
                width: 1,
              ),
            ),
            children: [
              if (widget.displayZoomActions) ...[
                ToolBarAction(
                  onPressed: () {
                    _controller.zoomOut();
                  },
                  child: Icon(
                    Icons.remove,
                    color: style.borderColor,
                  ),
                ),
                ToolBarAction(
                  onPressed: () {
                    _controller.zoomIn();
                  },
                  child: Icon(
                    Icons.add,
                    color: style.borderColor,
                  ),
                ),
              ],
              ...widget.actions
            ],
          ),
        ],
        if (widget.candles.length == 0)
          Expanded(
            child: Center(
              child: widget.loadingWidget ??
                  CircularProgressIndicator(color: style.loadingColor),
            ),
          )
        else
          Expanded(
            child: ChartComposer(
              controller: _controller,
              style: style,
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
          ),
      ],
    );
  }
}
