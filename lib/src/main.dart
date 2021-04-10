import 'dart:math';
import 'package:candlesticks/src/candle.dart';
import 'package:flutter/material.dart';
import './candle.dart';

class Candlesticks extends StatefulWidget {
  final List<Candle> candles;

  Candlesticks({required this.candles});

  @override
  _CandlesticksState createState() => _CandlesticksState();
}

class _CandlesticksState extends State<Candlesticks> {
  int index = 0;
  double candleWidth = 6;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onHorizontalDragUpdate: (detais) {
            double x = detais.delta.dx;
            setState(() {
              index -= x ~/ 2;
              index = max(index, 0);
            });
          },
          child: Container(
            color: Color.fromARGB(255, 18, 32, 47),
            child: CandlestickWidget(
              candles: widget.candles,
              candleWidth: candleWidth,
              index: index,
            ),
          ),
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

class CandlestickWidget extends LeafRenderObjectWidget {
  final List<Candle> candles;
  final int index;
  final double candleWidth;
  CandlestickWidget({
    required this.candles,
    required this.index,
    required this.candleWidth,
  });
  @override
  RenderObject createRenderObject(BuildContext context) {
    return CandlestickRenderObject(candles, index, candleWidth);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {
    CandlestickRenderObject candlestickRenderObject =
        renderObject as CandlestickRenderObject;
    candlestickRenderObject.index = index;
    candlestickRenderObject._candleWidth = candleWidth;
    candlestickRenderObject.markNeedsPaint();

    super.updateRenderObject(context, renderObject);
  }
}

class CandlestickRenderObject extends RenderBox {
  late List<Candle> _candles;
  late int _index;
  late double _candleWidth;

  CandlestickRenderObject(List<Candle> candles, int index, double candleWidth) {
    _candles = candles;
    _index = index;
    _candleWidth = candleWidth;
  }

  set index(int index) {
    if (_index == index) return;
    _index = index;
    markNeedsPaint();
  }

  set candleWidth(double candleWidth) {
    if (_candleWidth == candleWidth) return;
    _candleWidth = candleWidth;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = Size(constraints.maxWidth, constraints.maxHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    double high = 0;
    double low = double.infinity;
    for (int i = 0; i * _candleWidth < size.width; i++) {
      low = min(_candles[i + _index].low, low);
      high = max(_candles[i + _index].high, high);
    }
    double range = high - low;
    for (int i = 0; i * _candleWidth < size.width; i++) {
      var candle = _candles[i + _index];
      Color color = candle.open < candle.close
          ? Color.fromARGB(255, 71, 209, 253)
          : Colors.red;

      Paint paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      var path = Path()
        ..moveTo(offset.dx + i * _candleWidth + _candleWidth / 2,
            offset.dy + (high - candle.high) / range * size.height)
        ..relativeLineTo(0, (candle.high - candle.low) / range * size.height);

      context.canvas.drawPath(path, paint);
      paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      path = Path()
        ..addRect(Rect.fromPoints(
            Offset(offset.dx + i * _candleWidth + 0.5,
                offset.dy + (high - candle.close) / range * size.height),
            Offset(offset.dx + (i + 1) * _candleWidth - 0.5,
                offset.dy + (high - candle.open) / range * size.height)));
      context.canvas.drawPath(path, paint);
    }
    context.canvas.save();
    context.canvas.restore();
  }
}
