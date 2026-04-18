import 'dart:math';

import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:flutter/foundation.dart';

class CandlesticksController extends ValueNotifier<CandlesticksViewport> {
  CandlesticksController()
      : super(const CandlesticksViewport(scrollIndex: -10, candleWidth: 6));

  void jumpTo(int index) {
    value = value.copyWith(scrollIndex: index);
  }

  void setZoom(double width) {
    value = value.copyWith(candleWidth: width);
  }

  void zoomIn() {
    value = value.copyWith(candleWidth: min(value.candleWidth + 2, 20));
  }

  void zoomOut() {
    value = value.copyWith(candleWidth: max(value.candleWidth - 2, 2));
  }
}
