import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:flutter/foundation.dart';

class CandlesticksController extends ValueNotifier<CandlesticksViewport> {
  CandlesticksController()
      : super(const CandlesticksViewport(scrollIndex: -10, candleWidth: 6));

  static const double MAX_CANDLE_WIDTH = 20;
  static const double MIN_CANDLE_WIDTH = 0.25;

  void updateViewport({
    double? scrollIndex,
    double? candleWidth,
    int scrollIndexAnimationDurationMs = 0,
  }) {
    value = value.copyWith(
      scrollIndex: scrollIndex,
      candleWidth: candleWidth,
      scrollIndexAnimationDurationMs: scrollIndexAnimationDurationMs,
    );
  }

  void jumpTo(double index) {
    value = value.copyWith(scrollIndex: index);
  }

  void animateTo(double index) {
    value = value.copyWith(
      scrollIndex: index,
      scrollIndexAnimationDurationMs: 120,
    );
  }

  void jumpToCandle(int index) {
    jumpTo(index.toDouble());
  }

  void setZoom(double width) {
    value = value.copyWith(
        candleWidth: width.clamp(MIN_CANDLE_WIDTH, MAX_CANDLE_WIDTH));
  }

  void zoomBy(double factor) {
    value = value.copyWith(
        candleWidth: (value.candleWidth * factor)
            .clamp(MIN_CANDLE_WIDTH, MAX_CANDLE_WIDTH));
  }

  void zoomAround({
    required double zoomFactor,
    required double anchorDistanceFromRight,
    required int candlesCount,
  }) {
    final oldCandleWidth = value.candleWidth;
    final oldScrollIndex = value.scrollIndex;

    final hoveredIndex =
        oldScrollIndex + anchorDistanceFromRight / oldCandleWidth;

    final newCandleWidth = (oldCandleWidth * zoomFactor)
        .clamp(
          MIN_CANDLE_WIDTH,
          MAX_CANDLE_WIDTH,
        )
        .toDouble();

    if (newCandleWidth == oldCandleWidth) return;

    final newScrollIndex =
        hoveredIndex - anchorDistanceFromRight / newCandleWidth;

    const minScrollIndex = -10.0;
    final maxScrollIndex = candlesCount - 1.0;

    if (newScrollIndex < minScrollIndex || newScrollIndex > maxScrollIndex) {
      return;
    }

    value = value.copyWith(
      scrollIndex: newScrollIndex,
      candleWidth: newCandleWidth,
      scrollIndexAnimationDurationMs: 120,
      zoomAnchor: ZoomAnchor(
        index: hoveredIndex,
        distanceFromRight: anchorDistanceFromRight,
      ),
    );
  }

  void zoomIn() {
    zoomBy(1.33);
  }

  void zoomOut() {
    zoomBy(0.75);
  }
}
