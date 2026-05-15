import 'dart:math' as math;

import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:candlesticks/src/widgets/dash_line_painter.dart';
import 'package:flutter/material.dart';

/// Draws the horizontal time axis at the bottom of the chart.
///
/// This widget is responsible for:
///
/// - Drawing vertical grid lines aligned with candle centers.
/// - Drawing date/time text below those grid lines.
/// - Drawing the vertical crosshair line and hovered candle date label.
///
/// The axis is positioned directly from [CandlesticksViewport].
///
/// Coordinate model:
///
/// The chart is measured from the right side because candle index `0` is the
/// latest candle.
///
/// ```text
/// left side of chart                                          right side of chart
/// │                                                           │
/// candle 3      candle 2      candle 1      candle 0          │
///    │             │             │             │              │
///    ▼             ▼             ▼             ▼              │
/// ───┬─────────────┬─────────────┬─────────────┬──────────────┘
///    3             2             1             0
/// ```
///
/// The center of a candle is calculated like this:
///
/// ```dart
/// xFromRight = (candleIndex - scrollIndex + 0.5) * candleWidth;
/// ```
///
/// The `+ 0.5` is important because the grid line should pass through the
/// center of the candle, not its left or right edge.
class TimeAxis extends StatelessWidget {
  const TimeAxis({
    super.key,
    required this.candles,
    required this.viewport,
    this.crosshairXFromRight,
  });

  static const double _crosshairTextWidth = 110;
  static const double _crosshairTextHeight = 20;
  static const double _fontSize = 12;

  final List<Candle> candles;
  final CandlesticksViewport viewport;

  /// Crosshair position measured from the right side of the chart.
  ///
  /// This can point outside the loaded candle range. In that case, the time is
  /// estimated using the candle duration.
  final double? crosshairXFromRight;

  /// Returns how many candles should exist between two time-axis ticks.
  ///
  /// This always returns an odd number.
  ///
  /// Why odd?
  ///
  /// Each tick occupies this width:
  ///
  /// ```dart
  /// tickWidth = tickDistanceInCandles * candleWidth;
  /// ```
  ///
  /// Because the number is odd, the center candle of the tick block is a real
  /// candle. That lets the vertical grid line pass exactly through the center
  /// of a candle.
  ///
  /// Example with `tickDistanceInCandles = 9`:
  ///
  /// ```text
  /// ┌──────────────────── tick width ────────────────────┐
  ///   c0    c1    c2    c3    c4    c5    c6    c7    c8
  ///                           │
  ///                           │ grid line
  ///                           │
  /// ```
  int _tickDistanceInCandles() {
    final double candleWidth = viewport.candleWidth;

    if (candleWidth < 0.5) return 199;
    if (candleWidth < 1) return 121;
    if (candleWidth < 2) return 65;
    if (candleWidth < 3) return 31;
    if (candleWidth < 5) return 19;
    if (candleWidth < 7) return 13;

    return 9;
  }

  /// Returns the time duration between two neighboring candles.
  ///
  /// This assumes [candles] are sorted newest-first:
  ///
  /// ```text
  /// candles[0] = latest candle
  /// candles[1] = previous candle
  /// candles[2] = older candle
  /// ```
  Duration _candleDuration() {
    if (candles.length < 2) return Duration.zero;

    return candles.first.date.difference(candles[1].date);
  }

  /// Returns the date/time for any candle index.
  ///
  /// This supports indexes outside the loaded candle list.
  ///
  /// ```text
  /// index < 0
  ///   Future candles after the latest loaded candle.
  ///
  /// 0 <= index < candles.length
  ///   Real loaded candles.
  ///
  /// index >= candles.length
  ///   Estimated older candles before the oldest loaded candle.
  /// ```
  DateTime _dateAtCandleIndex({
    required int candleIndex,
    required Duration candleDuration,
  }) {
    if (candleIndex < 0) {
      return candles.first.date.add(
        Duration(
          milliseconds: candleDuration.inMilliseconds * -candleIndex,
        ),
      );
    }

    if (candleIndex < candles.length) {
      return candles[candleIndex].date;
    }

    final int extraCandlesAfterOldest = candleIndex - (candles.length - 1);

    return candles.last.date.subtract(
      Duration(
        milliseconds: candleDuration.inMilliseconds * extraCandlesAfterOldest,
      ),
    );
  }

  /// Builds all visible ticks using one positioned [Row].
  ///
  /// There is always a tick centered on the latest candle, index `0`.
  /// Other ticks are spaced by:
  ///
  /// ```dart
  /// tickWidth = tickDistanceInCandles * candleWidth;
  /// ```
  ///
  /// Diagram:
  ///
  /// ```text
  /// left side                                             right side
  /// │                                                      │
  /// │ tick 2           tick 1           tick 0          tick -1
  /// │   │                │                │                │
  /// │   │                │                │                │
  /// ────┼────────────────┼────────────────┼────────────────┼──
  ///                                       │
  ///                                       ▼
  ///                                    candle 0
  ///                                 latest candle
  /// ```
  Widget _buildTicks({
    required CandleSticksStyle style,
    required double width,
  }) {
    final int tickDistance = _tickDistanceInCandles();
    final double tickWidth = tickDistance * viewport.candleWidth;

    final Duration candleDuration = _candleDuration();
    final Duration tickDuration = candleDuration * tickDistance;

    /// Position of candle `0` center from the right side of the chart.
    ///
    /// If `scrollIndex == -10`, candle `0` is 10 candles away from the right,
    /// plus half a candle because we want its center.
    final double latestCandleCenterFromRight =
        (-viewport.scrollIndex + 0.5) * viewport.candleWidth;

    /// Find the first tick whose block may intersect the visible chart.
    ///
    /// Tick `0` is centered on the latest candle. Positive tick indexes go left
    /// toward older candles. Negative tick indexes go right, into the empty/future
    /// area after the latest candle.
    ///
    /// Each tick is a block with width [tickWidth]. Its grid line is centered
    /// inside that block. So a tick can still be partly visible even when its
    /// center is slightly outside the chart.
    ///
    /// Visible range from the right side:
    ///
    /// ```text
    /// right edge = 0
    /// left edge  = width
    /// ```
    ///
    /// A tick should be included if its block intersects this range.
    final int firstTickIndex =
        ((-tickWidth / 2 - latestCandleCenterFromRight) / tickWidth).floor();

    final int lastTickIndex =
        ((width + tickWidth / 2 - latestCandleCenterFromRight) / tickWidth)
            .ceil();

    final int tickCount = lastTickIndex - firstTickIndex + 1;

    if (tickCount <= 0) return const SizedBox.shrink();

    final double firstTickCenterFromRight =
        latestCandleCenterFromRight + firstTickIndex * tickWidth;

    /// The row starts half a tick before the first tick center.
    ///
    /// Each child has width [tickWidth], and its grid line is centered inside
    /// that child.
    final double rowRight = firstTickCenterFromRight - tickWidth / 2;
    final double rowWidth = tickCount * tickWidth;

    return Positioned(
      top: 0,
      bottom: 0,
      right: rowRight,
      width: rowWidth,
      child: Row(
        textDirection: TextDirection.rtl,
        children: <Widget>[
          for (int i = 0; i < tickCount; i++)
            _buildTick(
              tickIndex: firstTickIndex + i,
              tickDistance: tickDistance,
              tickWidth: tickWidth,
              candleDuration: candleDuration,
              tickDuration: tickDuration,
              style: style,
            ),
        ],
      ),
    );
  }

  /// Builds one tick block.
  ///
  /// A tick block has fixed width:
  ///
  /// ```dart
  /// tickWidth = tickDistance * candleWidth;
  /// ```
  ///
  /// The vertical grid line and the text are centered in this block.
  Widget _buildTick({
    required int tickIndex,
    required int tickDistance,
    required double tickWidth,
    required Duration candleDuration,
    required Duration tickDuration,
    required CandleSticksStyle style,
  }) {
    final int candleIndex = tickIndex * tickDistance;

    final DateTime date = _dateAtCandleIndex(
      candleIndex: candleIndex,
      candleDuration: candleDuration,
    );

    return SizedBox(
      width: tickWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Center(
              child: Container(
                width: 1,
                color: style.gridLineColor,
              ),
            ),
          ),
          _buildTickText(
            date: date,
            tickDuration: tickDuration,
            color: style.axisTextColor,
          ),
        ],
      ),
    );
  }

  /// Chooses whether a tick should show a time or a date.
  ///
  /// For small intervals, show time:
  ///
  /// ```text
  /// 12:30
  /// 13:00
  /// ```
  ///
  /// For larger intervals, show date:
  ///
  /// ```text
  /// May 5
  /// Jun 12
  /// ```
  Text _buildTickText({
    required DateTime date,
    required Duration tickDuration,
    required Color color,
  }) {
    if (tickDuration > const Duration(days: 1)) {
      return _buildDateText(
        date: date,
        tickDuration: tickDuration,
        color: color,
      );
    }

    return _buildTimeText(date, color);
  }

  /// Builds a date text for large time intervals.
  ///
  /// If this tick is the first visible tick of a new year, it shows only the
  /// year and makes it bold.
  ///
  /// Example:
  ///
  /// ```text
  /// Dec 20   2025   Jan 15
  /// ```
  Text _buildDateText({
    required DateTime date,
    required Duration tickDuration,
    required Color color,
  }) {
    final DateTime previousDate = date.subtract(tickDuration);
    final bool isFirstTickOfYear = previousDate.year != date.year;

    final String text = isFirstTickOfYear
        ? date.year.toString()
        : '${_monthName(date.month)} ${date.day}';

    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: _fontSize,
        fontWeight: isFirstTickOfYear ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Text _buildTimeText(DateTime date, Color color) {
    return Text(
      '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}',
      style: TextStyle(
        color: color,
        fontSize: _fontSize,
      ),
    );
  }

  int _nearestCandleIndexAtX(double xFromRight) {
    return (viewport.scrollIndex + xFromRight / viewport.candleWidth - 0.5)
        .round();
  }

  /// Builds the vertical crosshair line and the hovered date label.
  ///
  /// The available height comes from [LayoutBuilder], so the widget does not
  /// need a separate `maxHeight` parameter.
  Widget _buildCrosshair({
    required CandleSticksStyle style,
    required double xFromRight,
    required double height,
  }) {
    final int candleIndex = _nearestCandleIndexAtX(xFromRight);

    final DateTime date = _dateAtCandleIndex(
      candleIndex: candleIndex,
      candleDuration: _candleDuration(),
    );

    return Positioned(
      bottom: 0,
      right: math.max(xFromRight - _crosshairTextWidth / 2, 0),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              left: xFromRight > _crosshairTextWidth / 2
                  ? 0
                  : (_crosshairTextWidth / 2 - xFromRight) * 2,
            ),
            child: CustomPaint(
              size: Size(1, height),
              painter: DashLinePainter(
                direction: Axis.vertical,
                color: style.crosshairLineColor,
              ),
            ),
          ),
          Container(
            width: _crosshairTextWidth,
            height: _crosshairTextHeight,
            color: style.crosshairLabelBackgroundColor,
            alignment: Alignment.center,
            child: Text(
              _formatCrosshairDate(date),
              style: TextStyle(
                color: style.crosshairLabelTextColor,
                fontSize: _fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCrosshairDate(DateTime date) {
    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)} '
        '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _monthName(int month) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) return const SizedBox.shrink();

    final CandleSticksStyle style = CandleSticksStyleProvider.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            _buildTicks(
              style: style,
              width: constraints.maxWidth,
            ),
            if (crosshairXFromRight != null)
              _buildCrosshair(
                style: style,
                xFromRight: crosshairXFromRight!,
                height: constraints.maxHeight,
              ),
          ],
        );
      },
    );
  }
}
