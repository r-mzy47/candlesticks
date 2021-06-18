import 'dart:math';
import 'package:candlesticks/src/constant/intervals.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/theme/color_palette.dart';
import 'package:candlesticks/src/widgets/chart.dart';
import 'package:flutter/material.dart';
import 'models/candle.dart';

/// StatefulWidget that holds Chart's State (index of
/// current position and candles width).
class Candlesticks extends StatefulWidget {
  final List<Candle> candles;
  Candlesticks({required this.candles});

  @override
  _CandlesticksState createState() => _CandlesticksState();
}

/// [Candlesticks] state
class _CandlesticksState extends State<Candlesticks> {
  /// index of the newest candle to be displayed
  /// changes when user scrolls along the chart
  int index = -10;
  ScrollController scrollController = new ScrollController();

  /// candleWidth controls the width of the single candles.
  ///  range: [2...10]
  double candleWidth = 6;

  @override
  Widget build(BuildContext context) {
    if (widget.candles.length == 0)
      return Container(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    return Column(
      children: [
        Container(
          color: ColorPalette.barColor,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: RawMaterialButton(
                    fillColor: ColorPalette.barColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    onPressed: () {
                      setState(() {
                        candleWidth -= 2;
                        candleWidth = max(candleWidth, 2);
                      });
                    },
                    child: Icon(
                      Icons.remove,
                      color: Color.fromARGB(
                        255,
                        132,
                        142,
                        156,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 1,
                ),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: RawMaterialButton(
                    fillColor: ColorPalette.barColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    onPressed: () {
                      setState(() {
                        candleWidth += 2;
                        candleWidth = min(candleWidth, 10);
                      });
                    },
                    child: Icon(
                      Icons.add,
                      color: Color.fromARGB(
                        255,
                        132,
                        142,
                        156,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: RawMaterialButton(
                    fillColor: ColorPalette.barColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    onPressed: () {},
                    child: Text(
                      intervals[5],
                      style: TextStyle(
                        color: Color.fromARGB(
                          255,
                          132,
                          142,
                          156,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TweenAnimationBuilder(
            tween: Tween(begin: 6.toDouble(), end: candleWidth),
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutCirc,
            builder: (_, width, __) {
              return Chart(
                onScaleUpdate: (double scale) {
                  setState(() {
                    candleWidth *= scale;
                    candleWidth = min(candleWidth, 10);
                    candleWidth = max(candleWidth, 2);
                    candleWidth.toInt();
                  });
                },
                scrollController: scrollController,
                onHorizontalDragUpdate: (double x) {
                  setState(() {
                    index += x ~/ 2;
                    index = max(index, -10);
                    index = min(index, widget.candles.length - 1);
                  });
                  scrollController.jumpTo(index * candleWidth);
                },
                candleWidth: width as double,
                candles: widget.candles,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}
