import 'dart:math';

class ZoomAnchor {
  const ZoomAnchor({
    required this.index,
    required this.distanceFromRight,
  });

  final double index;
  final double distanceFromRight;
}

class CandlesticksViewport {
  const CandlesticksViewport({
    required this.scrollIndex,
    required this.candleWidth,
    this.scrollIndexAnimationDurationMs = 0,
    this.zoomAnchor,
  });

  final double scrollIndex;
  final double candleWidth;
  final int scrollIndexAnimationDurationMs;
  final ZoomAnchor? zoomAnchor;

  int get scrollIndexFloor => scrollIndex.floor();

  int get firstVisibleCandleIndex => max(scrollIndexFloor, 0);

  double get fractionalScrollOffset => scrollIndex - scrollIndexFloor;

  CandlesticksViewport copyWith({
    double? scrollIndex,
    double? candleWidth,
    int? scrollIndexAnimationDurationMs,
    ZoomAnchor? zoomAnchor,
  }) {
    return CandlesticksViewport(
      scrollIndex: scrollIndex ?? this.scrollIndex,
      candleWidth: candleWidth ?? this.candleWidth,
      scrollIndexAnimationDurationMs: scrollIndexAnimationDurationMs ?? 0,
      zoomAnchor: zoomAnchor,
    );
  }
}
