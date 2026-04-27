import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/widgets/dash_line_painter.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class TimeRow extends StatefulWidget {
  final List<Candle> candles;
  final int? hoverdCandleIndex;
  final CandlesticksViewport viewport;
  final CandleSticksStyle style;

  const TimeRow({
    Key? key,
    required this.candles,
    required this.viewport,
    this.hoverdCandleIndex,
    required this.style,
  }) : super(key: key);

  @override
  State<TimeRow> createState() => _TimeRowState();
}

class _TimeRowState extends State<TimeRow> {
  final ScrollController _scrollController = new ScrollController();

  /// Calculates number of candles between two time indicator
  int _stepCalculator() {
    if (widget.viewport.candleWidth < 0.5)
      return 199;
    else if (widget.viewport.candleWidth < 1)
      return 121;
    else if (widget.viewport.candleWidth < 2)
      return 65;
    else if (widget.viewport.candleWidth < 3)
      return 31;
    else if (widget.viewport.candleWidth < 5)
      return 19;
    else if (widget.viewport.candleWidth < 7)
      return 13;
    else
      return 9;
  }

  /// Calculates [DateTime] of a given candle index
  DateTime _timeCalculator(int step, int index, Duration dif) {
    int candleNumber = (step + 1) ~/ 2 - 10 + index * step + -1;
    DateTime? _time;
    if (candleNumber < 0)
      _time = widget.candles[0].date.add(Duration(
          milliseconds: dif.inMilliseconds ~/ -1 * step * candleNumber));
    else if (candleNumber < widget.candles.length)
      _time = widget.candles[candleNumber].date;
    else {
      _time = widget.candles[0].date.subtract(
          Duration(milliseconds: dif.inMilliseconds ~/ step * candleNumber));
    }
    return _time;
  }

  /// Fomats number as 2 digit integer
  String numberFormat(int value) {
    return "${value < 10 ? 0 : ""}$value";
  }

  /// Day/month text widget
  Text _monthDayText(DateTime _time, Color color) {
    return Text(
      numberFormat(_time.month) + "/" + numberFormat(_time.day),
      style: TextStyle(
        color: color,
        fontSize: 12,
      ),
    );
  }

  /// Hour/minute text widget
  Text _hourMinuteText(DateTime _time, Color color) {
    return Text(
      numberFormat(_time.hour) + ":" + numberFormat(_time.minute),
      style: TextStyle(
        color: color,
        fontSize: 12,
      ),
    );
  }

  String dateFormatter(DateTime date) {
    return "${date.year}-${numberFormat(date.month)}-${numberFormat(date.day)} ${numberFormat(date.hour)}:${numberFormat(date.minute)}";
  }

  @override
  void didUpdateWidget(TimeRow oldWidget) {
    if (oldWidget.viewport != widget.viewport)
      _scrollController.jumpTo(
          (widget.viewport.scrollIndex + 10) * widget.viewport.candleWidth);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    int step = _stepCalculator();
    final dif =
        widget.candles[0].date.difference(widget.candles[1].date) * step;
    double? hoveredCandlePosition = widget.hoverdCandleIndex == null
        ? null
        : (widget.hoverdCandleIndex! - widget.viewport.scrollIndex + 0.5) *
            widget.viewport.candleWidth;
    return Stack(
      children: [
        ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          itemCount: math.max(widget.candles.length, 1000),
          scrollDirection: Axis.horizontal,
          itemExtent: step * widget.viewport.candleWidth,
          controller: _scrollController,
          reverse: true,
          itemBuilder: (context, index) {
            DateTime _time = _timeCalculator(step, index, dif);
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Container(
                    width: 1,
                    color: widget.style.gridColor,
                  ),
                ),
                dif.compareTo(Duration(days: 1)) > 0
                    ? _monthDayText(_time, widget.style.primaryTextColor)
                    : _hourMinuteText(_time, widget.style.primaryTextColor),
              ],
            );
          },
        ),
        hoveredCandlePosition == null
            ? Container()
            : Positioned(
                bottom: 0,
                right: math.max(hoveredCandlePosition - 55, 0),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: hoveredCandlePosition > 55
                            ? 0
                            : (55 - hoveredCandlePosition) * 2,
                      ),
                      child: CustomPaint(
                        size: Size(1, 1000),
                        painter: DashLinePainter(
                          direction: Axis.vertical,
                          color: widget.style.borderColor,
                        ),
                      ),
                    ),
                    Container(
                      color: widget.style.hoverIndicatorBackgroundColor,
                      child: Center(
                        child: Text(
                          dateFormatter(
                              widget.candles[widget.hoverdCandleIndex!].date),
                          style: TextStyle(
                            color: widget.style.secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      width: 110,
                      height: 20,
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}
