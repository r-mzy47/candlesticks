import 'package:candlesticks/src/models/candle.dart';
import 'package:flutter/material.dart';
import '../models/candle.dart';

class VolumeWidget extends LeafRenderObjectWidget {
  final List<Candle> candles;
  final int index;
  final double barWidth;
  final double high;
  final Color bullColor;
  final Color bearColor;

  VolumeWidget({
    required this.candles,
    required this.index,
    required this.barWidth,
    required this.high,
    required this.bearColor,
    required this.bullColor,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return VolumeRenderObject(
      candles,
      index,
      barWidth,
      high,
      bearColor,
      bullColor,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {
    VolumeRenderObject candlestickRenderObject =
        renderObject as VolumeRenderObject;
    candlestickRenderObject._candles = candles;
    candlestickRenderObject._index = index;
    candlestickRenderObject._barWidth = barWidth;
    candlestickRenderObject._high = high;
    candlestickRenderObject._bearColor = bearColor;
    candlestickRenderObject._bullColor = bullColor;
    candlestickRenderObject.markNeedsPaint();
    super.updateRenderObject(context, renderObject);
  }
}

class VolumeRenderObject extends RenderBox {
  late List<Candle> _candles;
  late int _index;
  late double _barWidth;
  late double _high;
  late Color _bearColor;
  late Color _bullColor;

  VolumeRenderObject(
    List<Candle> candles,
    int index,
    double barWidth,
    double high,
    Color bearColor,
    Color bullColor,
  ) {
    _candles = candles;
    _index = index;
    _barWidth = barWidth;
    _high = high;
    _bearColor = bearColor;
    _bullColor = bullColor;
  }

  /// set size as large as possible
  @override
  void performLayout() {
    size = Size(constraints.maxWidth, constraints.maxHeight);
  }

  /// draws a single candle
  void paintBar(PaintingContext context, Offset offset, int index,
      Candle candle, double range) {
    Color color = candle.isBull ? _bullColor : _bearColor;

    double x = size.width + offset.dx - (index + 0.5) * _barWidth;

    context.canvas.drawLine(
        Offset(x, offset.dy + (_high - candle.volume) / range),
        Offset(x, offset.dy + size.height),
        Paint()
          ..color = color
          ..strokeWidth = _barWidth - 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    double range = (_high) / size.height;
    for (int i = 0; (i + 1) * _barWidth < size.width; i++) {
      if (i + _index >= _candles.length || i + _index < 0) continue;
      var candle = _candles[i + _index];
      paintBar(context, offset, i, candle, range);
    }
    context.canvas.save();
    context.canvas.restore();
  }
}
