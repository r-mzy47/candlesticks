import 'dart:math';

/// Describes the candle position that should stay fixed during anchored zooming.
///
/// This is used when zooming around a pointer position. For example, when
/// the user zooms with Control/Command + mouse wheel, the candle under the
/// pointer should stay visually anchored instead of drifting away.
class ZoomAnchor {
  /// Creates a zoom anchor.
  const ZoomAnchor({
    required this.index,
    required this.distanceFromRight,
  });

  /// The candle index that should stay anchored during zooming.
  ///
  /// This value can be fractional because the pointer can be between two
  /// candles.
  final double index;

  /// The anchor position measured from the right side of the chart.
  ///
  /// This is expressed in logical pixels.
  final double distanceFromRight;
}

/// Immutable viewport state for a [Candlesticks] chart.
///
/// The viewport stores the current horizontal scroll position, candle width,
/// optional scroll animation duration, and optional zoom anchor.
///
/// This object is held by [CandlesticksController.value]. It is immutable, so
/// use [copyWith] to create an updated viewport.
class CandlesticksViewport {
  /// Creates a chart viewport.
  const CandlesticksViewport({
    required this.scrollIndex,
    required this.candleWidth,
    this.scrollIndexAnimationDurationMs = 0,
    this.zoomAnchor,
  });

  /// The horizontal scroll position of the chart.
  ///
  /// The value represents the candle index at the right side of the viewport.
  /// It can be fractional to support smooth scrolling.
  ///
  /// A value of `0` places the newest candle at the right edge. Negative values
  /// allow empty space after the newest candle.
  final double scrollIndex;

  /// The width of each candle in logical pixels.
  ///
  /// This value controls the horizontal zoom level of the chart.
  final double candleWidth;

  /// Duration, in milliseconds, used when animating scroll changes.
  ///
  /// A value of `0` means the viewport should update immediately.
  final int scrollIndexAnimationDurationMs;

  /// Optional anchor used by zoom gestures.
  ///
  /// When this is not null, the chart can keep [ZoomAnchor.index] at
  /// [ZoomAnchor.distanceFromRight] while the candle width changes.
  final ZoomAnchor? zoomAnchor;

  /// The integer part of [scrollIndex].
  ///
  /// This is useful when calculating visible candle indexes while preserving
  /// [fractionalScrollOffset] for smooth movement.
  int get scrollIndexFloor => scrollIndex.floor();

  /// The first candle index that should be considered visible.
  ///
  /// This value never returns a negative index.
  int get firstVisibleCandleIndex => max(scrollIndexFloor, 0);

  /// The fractional part of [scrollIndex].
  ///
  /// This is used to draw smooth horizontal movement between whole candle
  /// indexes.
  double get fractionalScrollOffset => scrollIndex - scrollIndexFloor;

  /// Creates a copy of this viewport with updated values.
  ///
  /// If [scrollIndexAnimationDurationMs] is omitted, it resets to `0`.
  ///
  /// If [zoomAnchor] is omitted, the copied viewport clears the current zoom
  /// anchor.
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
