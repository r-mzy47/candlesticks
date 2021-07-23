import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/theme/color_palette.dart';
import 'package:flutter/material.dart';
import '../models/candle.dart';

/// This widget extends [LeafRenderObjectWidget]
/// And uses CandleStickRenderObject for painting the chart.
class CandleStickWidget extends LeafRenderObjectWidget {
  final List<Candle> candles;
  final int index;
  final double candleWidth;
  final double high;
  final double low;
  CandleStickWidget({
    required this.candles,
    required this.index,
    required this.candleWidth,
    required this.low,
    required this.high,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return CandleStickRenderObject(
      candles,
      index,
      candleWidth,
      low,
      high,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {
    CandleStickRenderObject candlestickRenderObject =
        renderObject as CandleStickRenderObject;
    candlestickRenderObject._candles = candles;
    candlestickRenderObject.index = index;
    candlestickRenderObject._candleWidth = candleWidth;
    candlestickRenderObject._high = high;
    candlestickRenderObject._low = low;
    candlestickRenderObject.markNeedsPaint();
    super.updateRenderObject(context, renderObject);
  }
}

/// This render object is responsible for
/// drawing the configured chart on the canvas.
class CandleStickRenderObject extends RenderBox {
  late List<Candle> _candles;
  late int _index;
  late double _candleWidth;
  late double _low;
  late double _high;

  CandleStickRenderObject(
    List<Candle> candles,
    int index,
    double candleWidth,
    double low,
    double high,
  ) {
    _candles = candles;
    _index = index;
    _candleWidth = candleWidth;
    _low = low;
    _high = high;
  }

  set index(int index) {
    if (_index == index) return;
    _index = index;
  }

  set candleWidth(double candleWidth) {
    if (_candleWidth == candleWidth) return;
    _candleWidth = candleWidth;
  }

  set high(double high) {
    _high = high;
  }

  set low(double low) {
    _low = low;
  }

  /// set size as large as possible
  @override
  void performLayout() {
    size = Size(constraints.maxWidth, constraints.maxHeight);
  }

  /// draws a single candle
  void paintCandle(PaintingContext context, Offset offset, int index,
      Candle candle, double range) {
    Color color =
        candle.open < candle.close ? ColorPalette.green : ColorPalette.red;
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    var path = Path()
      ..moveTo(size.width + offset.dx - (index + 0.5) * _candleWidth,
          offset.dy + (_high - candle.high) / range)
      ..relativeLineTo(0, (candle.high - candle.low) / range);

    context.canvas.drawPath(path, paint);
    paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    path = Path()
      ..addRect(Rect.fromPoints(
          Offset(size.width + offset.dx - (index * _candleWidth + 0.5),
              offset.dy + (_high - candle.close) / range),
          Offset(size.width + offset.dx - ((index + 1) * _candleWidth - 0.5),
              offset.dy + (_high - candle.open) / range)));
    context.canvas.drawPath(path, paint);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    double range = (_high - _low) / size.height;
    for (int i = 0; (i + 1) * _candleWidth < size.width; i++) {
      if (i + _index >= _candles.length || i + _index < 0) continue;
      var candle = _candles[i + _index];
      paintCandle(context, offset, i, candle, range);
    }
    context.canvas.save();
    context.canvas.restore();
  }
}
