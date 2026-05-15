import 'dart:math' as math;

import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:flutter/foundation.dart';

/// Controls the scroll and zoom state of a [Candlesticks] chart.
///
/// A [CandlesticksController] exposes the current [CandlesticksViewport] through
/// [value]. It can be used to programmatically scroll, animate, zoom, and listen
/// for viewport changes.
///
/// Example:
///
/// ```dart
/// final controller = CandlesticksController();
///
/// Candlesticks(
///   candles: candles,
///   controller: controller,
/// )
///
/// controller.zoomIn();
/// controller.jumpToCandle(20);
/// ```
///
/// The controller also tracks whether the visible range is close to the oldest
/// loaded candle through [isNearEnd]. This is useful for implementing
/// "load more" behavior.
class CandlesticksController extends ValueNotifier<CandlesticksViewport> {
  /// Creates a controller with the default viewport.
  ///
  /// By default, the chart starts with empty space after the newest candle and
  /// uses a candle width of `6` logical pixels.
  CandlesticksController()
      : super(
          const CandlesticksViewport(
            scrollIndex: -10,
            candleWidth: 6,
          ),
        );

  /// The maximum allowed candle width.
  ///
  /// This limits how far users can zoom in.
  static const double MAX_CANDLE_WIDTH = 20;

  /// The minimum allowed candle width.
  ///
  /// This limits how far users can zoom out.
  static const double MIN_CANDLE_WIDTH = 0.25;

  /// How many candles before the oldest loaded candle should count as near end.
  ///
  /// When the last visible candle reaches this threshold, [isNearEnd] becomes
  /// true.
  static const int NEAR_END_THRESHOLD = 20;

  int _candlesCount = 0;
  double _chartWidth = 0;
  bool _isNearEnd = false;

  /// Number of candles currently available in the chart.
  int get candlesCount => _candlesCount;

  /// Width of the candle drawing area, excluding the price bar.
  ///
  /// This value is used for scroll bounds and visible range calculations.
  double get chartWidth => _chartWidth;

  /// Whether the visible range is close to the oldest loaded candle.
  ///
  /// Users can listen to this controller and fetch more candles when this
  /// becomes true.
  ///
  /// Example:
  ///
  /// ```dart
  /// controller.addListener(() {
  ///   if (controller.isNearEnd) {
  ///     loadMoreCandles();
  ///   }
  /// });
  /// ```
  bool get isNearEnd => _isNearEnd;

  /// Updates chart metrics used for clamping and visible range calculations.
  ///
  /// This should be called by the chart when the candle count or chart width
  /// changes.
  ///
  /// This method is safe to call inside `LayoutBuilder` because it does not
  /// update [value] and does not notify listeners.
  ///
  /// Returns true when either [candlesCount] or [chartWidth] changed.
  bool updateChartMetrics({
    required int candlesCount,
    required double chartWidth,
  }) {
    final safeCandlesCount = math.max(0, candlesCount);
    final safeChartWidth = math.max(0.0, chartWidth);

    if (_candlesCount == safeCandlesCount && _chartWidth == safeChartWidth) {
      return false;
    }

    _candlesCount = safeCandlesCount;
    _chartWidth = safeChartWidth;
    return true;
  }

  /// Syncs the current viewport with the latest chart metrics.
  ///
  /// Call this after build, for example with `addPostFrameCallback`, when
  /// [updateChartMetrics] returns true.
  ///
  /// This clamps the current scroll index and candle width to the latest chart
  /// bounds.
  void syncViewportWithMetrics() {
    final nextCandleWidth = _clampCandleWidth(value.candleWidth);
    final nextViewport = value.copyWith(
      candleWidth: nextCandleWidth,
      scrollIndex: _clampScrollIndexWithCandleWidth(
        value.scrollIndex,
        nextCandleWidth,
      ),
      scrollIndexAnimationDurationMs: 0,
    );

    _commitViewport(nextViewport);
  }

  /// Updates the viewport directly.
  ///
  /// Any provided [scrollIndex] or [candleWidth] is clamped to valid chart
  /// bounds before being applied.
  ///
  /// Use [scrollIndexAnimationDurationMs] to request an animated scroll update.
  void updateViewport({
    double? scrollIndex,
    double? candleWidth,
    int scrollIndexAnimationDurationMs = 0,
  }) {
    final nextCandleWidth = candleWidth == null
        ? value.candleWidth
        : _clampCandleWidth(candleWidth);

    final nextScrollIndex = scrollIndex ?? value.scrollIndex;

    final nextViewport = value.copyWith(
      scrollIndex: _clampScrollIndexWithCandleWidth(
        nextScrollIndex,
        nextCandleWidth,
      ),
      candleWidth: nextCandleWidth,
      scrollIndexAnimationDurationMs: scrollIndexAnimationDurationMs,
    );

    _commitViewport(nextViewport);
  }

  /// Scrolls the chart horizontally by a pixel delta.
  ///
  /// Positive and negative values move the viewport in opposite directions.
  /// The pixel delta is converted to candle units using the current
  /// [CandlesticksViewport.candleWidth].
  void scrollByPixels({
    required double deltaX,
  }) {
    final newScrollIndex = value.scrollIndex - deltaX / value.candleWidth;

    final nextViewport = value.copyWith(
      scrollIndex: _clampScrollIndexWithCandleWidth(
        newScrollIndex,
        value.candleWidth,
      ),
      scrollIndexAnimationDurationMs: 0,
    );

    _commitViewport(nextViewport);
  }

  /// Jumps to a specific scroll index without animation.
  ///
  /// The [index] represents the candle index at the right side of the viewport.
  void jumpTo(double index) {
    final nextViewport = value.copyWith(
      scrollIndex: _clampScrollIndexWithCandleWidth(
        index,
        value.candleWidth,
      ),
      scrollIndexAnimationDurationMs: 0,
    );

    _commitViewport(nextViewport);
  }

  /// Animates to a specific scroll index.
  ///
  /// The [index] represents the candle index at the right side of the viewport.
  void animateTo(double index) {
    final nextViewport = value.copyWith(
      scrollIndex: _clampScrollIndexWithCandleWidth(
        index,
        value.candleWidth,
      ),
      scrollIndexAnimationDurationMs: 120,
    );

    _commitViewport(nextViewport);
  }

  /// Jumps to a specific candle index without animation.
  void jumpToCandle(int index) {
    jumpTo(index.toDouble());
  }

  /// Sets the candle width.
  ///
  /// The [width] is clamped between [MIN_CANDLE_WIDTH] and [MAX_CANDLE_WIDTH].
  void setZoom(double width) {
    final newCandleWidth = _clampCandleWidth(width);

    final nextViewport = value.copyWith(
      candleWidth: newCandleWidth,
      scrollIndex: _clampScrollIndexWithCandleWidth(
        value.scrollIndex,
        newCandleWidth,
      ),
    );

    _commitViewport(nextViewport);
  }

  /// Multiplies the current candle width by [factor].
  ///
  /// Values greater than `1` zoom in. Values between `0` and `1` zoom out.
  void zoomBy(double factor) {
    final newCandleWidth = _clampCandleWidth(value.candleWidth * factor);

    final nextViewport = value.copyWith(
      candleWidth: newCandleWidth,
      scrollIndex: _clampScrollIndexWithCandleWidth(
        value.scrollIndex,
        newCandleWidth,
      ),
    );

    _commitViewport(nextViewport);
  }

  /// Zooms around a fixed chart position.
  ///
  /// This is useful for Control/Command + mouse wheel zooming, where the candle
  /// under the pointer should stay visually anchored while the candle width
  /// changes.
  ///
  /// [zoomFactor] is multiplied by the current candle width.
  ///
  /// [anchorDistanceFromRight] is the pointer position measured from the right
  /// side of the candle drawing area.
  void zoomAround({
    required double zoomFactor,
    required double anchorDistanceFromRight,
  }) {
    final oldCandleWidth = value.candleWidth;
    final oldScrollIndex = value.scrollIndex;
    final hoveredIndex =
        oldScrollIndex + anchorDistanceFromRight / oldCandleWidth;

    final newCandleWidth = _clampCandleWidth(oldCandleWidth * zoomFactor);
    if (newCandleWidth == oldCandleWidth) return;

    final newScrollIndex =
        hoveredIndex - anchorDistanceFromRight / newCandleWidth;

    final nextViewport = value.copyWith(
      scrollIndex: _clampScrollIndexWithCandleWidth(
        newScrollIndex,
        newCandleWidth,
      ),
      candleWidth: newCandleWidth,
      scrollIndexAnimationDurationMs: 120,
      zoomAnchor: ZoomAnchor(
        index: hoveredIndex,
        distanceFromRight: anchorDistanceFromRight,
      ),
    );

    _commitViewport(nextViewport);
  }

  /// Zooms in by a fixed step.
  void zoomIn() {
    zoomBy(1.33);
  }

  /// Zooms out by a fixed step.
  void zoomOut() {
    zoomBy(0.75);
  }

  /// Returns how many candles fit in the visible chart area for [viewport].
  int visibleCandlesCountFor(CandlesticksViewport viewport) {
    if (_chartWidth <= 0) return 0;
    if (viewport.candleWidth <= 0) return 0;

    return math.max(1, (_chartWidth / viewport.candleWidth).ceil());
  }

  /// Returns the first visible candle index for [viewport].
  int firstVisibleCandleIndexFor(CandlesticksViewport viewport) {
    if (_candlesCount <= 0) return 0;

    return viewport.firstVisibleCandleIndex.clamp(0, _candlesCount - 1).toInt();
  }

  /// Returns the last visible candle index for [viewport].
  int lastVisibleCandleIndexFor(CandlesticksViewport viewport) {
    if (_candlesCount <= 0) return 0;

    final firstVisibleIndex = firstVisibleCandleIndexFor(viewport);
    final visibleCandlesCount = visibleCandlesCountFor(viewport);

    return math.min(
      firstVisibleIndex + visibleCandlesCount - 1,
      _candlesCount - 1,
    );
  }

  double _maxScrollIndex() {
    if (_candlesCount <= 0) return 0;

    return _candlesCount - 1.0;
  }

  double _minScrollIndexForCandleWidth(double candleWidth) {
    if (_chartWidth <= 0) return value.scrollIndex;
    if (candleWidth <= 0) return value.scrollIndex;

    final visibleCandleSlots = _chartWidth / candleWidth;

    // If one candle is wider than the chart, do not allow negative scrolling.
    if (visibleCandleSlots <= 1) return 0;

    // Allow scrolling right only until at least one candle is still visible.
    return -(visibleCandleSlots - 1);
  }

  double _clampScrollIndexWithCandleWidth(
    double scrollIndex,
    double candleWidth,
  ) {
    if (_candlesCount <= 0) return 0;

    final minScrollIndex = _minScrollIndexForCandleWidth(candleWidth);
    final maxScrollIndex = _maxScrollIndex();

    return scrollIndex.clamp(minScrollIndex, maxScrollIndex).toDouble();
  }

  double _clampCandleWidth(double candleWidth) {
    return candleWidth.clamp(MIN_CANDLE_WIDTH, MAX_CANDLE_WIDTH).toDouble();
  }

  bool _calculateIsNearEnd(CandlesticksViewport viewport) {
    if (_candlesCount <= 0) return false;
    if (_chartWidth <= 0) return false;

    final lastVisibleIndex = lastVisibleCandleIndexFor(viewport);
    final nearEndIndex = _candlesCount - 1 - NEAR_END_THRESHOLD;

    return lastVisibleIndex >= nearEndIndex;
  }

  void _commitViewport(CandlesticksViewport nextViewport) {
    final nextIsNearEnd = _calculateIsNearEnd(nextViewport);
    final nearEndChanged = _isNearEnd != nextIsNearEnd;
    final viewportChanged = !_sameViewport(value, nextViewport);

    _isNearEnd = nextIsNearEnd;

    if (viewportChanged) {
      value = nextViewport;
      return;
    }

    if (nearEndChanged) {
      notifyListeners();
    }
  }

  bool _sameViewport(
    CandlesticksViewport a,
    CandlesticksViewport b,
  ) {
    return a.scrollIndex == b.scrollIndex &&
        a.candleWidth == b.candleWidth &&
        a.scrollIndexAnimationDurationMs == b.scrollIndexAnimationDurationMs &&
        a.zoomAnchor == b.zoomAnchor;
  }
}
