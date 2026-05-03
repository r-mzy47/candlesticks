import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:flutter/foundation.dart';

class CandlesticksController extends ValueNotifier<CandlesticksViewport> {
  CandlesticksController()
      : super(const CandlesticksViewport(scrollIndex: -10, candleWidth: 6));

  static const double MAX_CANDLE_WIDTH = 20;
  static const double MIN_CANDLE_WIDTH = 0.25;

  void jumpTo(int index) {
    value = value.copyWith(scrollIndex: index);
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

  void zoomIn() {
    zoomBy(1.33);
  }

  void zoomOut() {
    zoomBy(0.75);
  }
}
