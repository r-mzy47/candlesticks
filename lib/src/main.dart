import 'dart:math';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:flutter/material.dart';
import 'models/candle.dart';

/// StatefulWidget that holds Chart's State (index of
/// current position and candles width) and manages gestures.
class Candlesticks extends StatefulWidget {
  final List<Candle> candles;

  Candlesticks({required this.candles});

  @override
  _CandlesticksState createState() => _CandlesticksState();
}

class _CandlesticksState extends State<Candlesticks> {
  int index = -10;
  double candleWidth = 6;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TweenAnimationBuilder(
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
              onHorizontalDragUpdate: (double x) {
                setState(() {
                  index += x ~/ 2;
                  index = max(index, -10);
                  index = min(index, widget.candles.length - 1);
                });
              },
              candleWidth: width as double,
              candles: widget.candles,
              index: index,
            );
          },
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: RawMaterialButton(
                    fillColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    onPressed: () {
                      setState(() {
                        candleWidth -= 2;
                        candleWidth = max(candleWidth, 2);
                      });
                    },
                    child: Icon(Icons.remove),
                  ),
                ),
                SizedBox(
                  width: 1,
                ),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: RawMaterialButton(
                    fillColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    onPressed: () {
                      setState(() {
                        candleWidth += 2;
                        candleWidth = min(candleWidth, 10);
                      });
                    },
                    child: Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// This widget calculates the highest and lowest price of visible candles.
/// Updates right-hand side numbers.
/// And pass values down to [CandleStickWidget].
class Chart extends StatelessWidget {
  final Function onScaleUpdate;
  final Function onHorizontalDragUpdate;
  final double candleWidth;
  final List<Candle> candles;
  final int index;

  Chart({
    required this.onScaleUpdate,
    required this.onHorizontalDragUpdate,
    required this.candleWidth,
    required this.candles,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double high = 0;
        double low = double.infinity;
        for (int i = 0;
            (i + 1) * candleWidth < constraints.maxWidth - 50;
            i++) {
          if (i + index >= candles.length || i + index < 0) continue;
          low = min(candles[i + index].low, low);
          high = max(candles[i + index].high, high);
        }
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onScaleUpdate: (ScaleUpdateDetails scaleUpdateDetails) {
                  if (scaleUpdateDetails.scale == 1.0) {
                    return;
                  }
                  onScaleUpdate(scaleUpdateDetails.scale);
                },
                onHorizontalDragUpdate: (detais) {
                  double x = detais.delta.dx;
                  onHorizontalDragUpdate(x);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(
                        255, 25, 27, 32), //Color.fromARGB(255, 18, 32, 47),
                    border: Border.all(
                      color: Color.fromARGB(255, 132, 142, 156),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: CandleStickWidget(
                      candles: candles,
                      candleWidth: candleWidth,
                      index: index,
                      high: high,
                      low: low,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 50,
              color: Color.fromARGB(255, 25, 27, 32),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "-${high.toInt()}",
                      style: TextStyle(
                        color: Color.fromARGB(255, 132, 142, 156),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "-${low.toInt()}",
                      style: TextStyle(
                        color: Color.fromARGB(255, 132, 142, 156),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
