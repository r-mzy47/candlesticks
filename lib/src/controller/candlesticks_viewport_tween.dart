import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:flutter/widgets.dart';

class CandlesticksViewportTween extends Tween<CandlesticksViewport> {
  CandlesticksViewportTween({
    super.begin,
    required super.end,
  });

  static const int candleWidthAnimationMs = 120;

  int get durationMs =>
      math.max(candleWidthAnimationMs, end!.scrollIndexAnimationDurationMs);

  @override
  CandlesticksViewport lerp(double t) {
    final b = begin!;
    final e = end!;
    final totalMs = durationMs;

    final widthT = (t * totalMs / candleWidthAnimationMs).clamp(0.0, 1.0);
    final width = lerpDouble(b.candleWidth, e.candleWidth, widthT)!;

    final anchor = e.zoomAnchor;

    final scrollIndex = anchor != null
        ? anchor.index - anchor.distanceFromRight / width
        : e.scrollIndexAnimationDurationMs == 0
            ? e.scrollIndex
            : lerpDouble(
                b.scrollIndex,
                e.scrollIndex,
                (t * totalMs / e.scrollIndexAnimationDurationMs)
                    .clamp(0.0, 1.0),
              )!;

    return CandlesticksViewport(
      scrollIndex: scrollIndex,
      candleWidth: width,
      scrollIndexAnimationDurationMs: e.scrollIndexAnimationDurationMs,
      zoomAnchor: e.zoomAnchor,
    );
  }
}
