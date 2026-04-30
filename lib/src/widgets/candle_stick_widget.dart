import 'package:candlesticks/src/models/candle.dart';
import 'package:flutter/material.dart';

class CandleStickWidget extends LeafRenderObjectWidget {
  final List<Candle> candles;
  final int index;
  final double candleWidth;
  final double high;
  final double low;
  final Color bullColor;
  final Color bearColor;

  const CandleStickWidget({
    super.key,
    required this.candles,
    required this.index,
    required this.candleWidth,
    required this.low,
    required this.high,
    required this.bearColor,
    required this.bullColor,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return CandleStickRenderObject(
      candles: candles,
      index: index,
      candleWidth: candleWidth,
      low: low,
      high: high,
      bullColor: bullColor,
      bearColor: bearColor,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant CandleStickRenderObject renderObject,
  ) {
    renderObject
      ..index = index
      ..candles = candles
      ..candleWidth = candleWidth
      ..low = low
      ..high = high
      ..bullColor = bullColor
      ..bearColor = bearColor;
  }
}

class CandleStickRenderObject extends RenderBox {
  CandleStickRenderObject({
    required List<Candle> candles,
    required int index,
    required double candleWidth,
    required double low,
    required double high,
    required Color bullColor,
    required Color bearColor,
  })  : _candles = candles,
        _index = index,
        _candleWidth = candleWidth,
        _low = low,
        _high = high,
        _bullColor = bullColor,
        _bearColor = bearColor,
        _latestClose = candles.isEmpty ? null : candles.first.close,
        _candlesLength = candles.length;

  List<Candle> _candles;
  int _index;
  double _candleWidth;
  double _low;
  double _high;
  Color _bullColor;
  Color _bearColor;

  double? _latestClose;
  int _candlesLength;

  @override
  bool get isRepaintBoundary => true;

  set candles(List<Candle> value) {
    final oldLatestClose = _latestClose;
    final oldCandlesLength = _candlesLength;

    final newLatestClose = value.isEmpty ? null : value.first.close;
    final newCandlesLength = value.length;

    _candles = value;
    _latestClose = newLatestClose;
    _candlesLength = newCandlesLength;

    final latestCandleChanged = oldLatestClose != newLatestClose;
    final candlesLengthChanged = oldCandlesLength != newCandlesLength;

    if (candlesLengthChanged || (_index <= 0 && latestCandleChanged)) {
      markNeedsPaint();
    }
  }

  set index(int value) {
    if (_index == value) return;

    _index = value;
    markNeedsPaint();
  }

  set candleWidth(double value) {
    if (_candleWidth == value) return;

    _candleWidth = value;
    markNeedsPaint();
  }

  set low(double value) {
    if (_low == value) return;

    _low = value;
    markNeedsPaint();
  }

  set high(double value) {
    if (_high == value) return;

    _high = value;
    markNeedsPaint();
  }

  set bullColor(Color value) {
    if (_bullColor == value) return;

    _bullColor = value;
    markNeedsPaint();
  }

  set bearColor(Color value) {
    if (_bearColor == value) return;

    _bearColor = value;
    markNeedsPaint();
  }

  /// set size as large as possible
  @override
  void performLayout() {
    size = constraints.biggest;
  }

  void _paintCandle(
    Canvas canvas,
    Offset offset,
    int visibleIndex,
    Candle candle,
    Paint wickPaint,
    Paint bodyPaint,
    double pricePerPixel,
  ) {
    final color = candle.isBull ? _bullColor : _bearColor;

    wickPaint.color = color;
    bodyPaint.color = color;

    final x = size.width + offset.dx - (visibleIndex + 0.5) * _candleWidth;

    final highY = offset.dy + (_high - candle.high) / pricePerPixel;
    final lowY = offset.dy + (_high - candle.low) / pricePerPixel;
    final openY = offset.dy + (_high - candle.open) / pricePerPixel;
    final closeY = offset.dy + (_high - candle.close) / pricePerPixel;

    canvas.drawLine(
      Offset(x, highY),
      Offset(x, lowY),
      wickPaint,
    );

    if (_candleWidth <= 1) {
      return;
    }

    if ((openY - closeY).abs() > 1) {
      canvas.drawLine(
        Offset(x, openY),
        Offset(x, closeY),
        bodyPaint,
      );
    } else {
      final mid = (openY + closeY) / 2;

      canvas.drawLine(
        Offset(x, mid - 0.5),
        Offset(x, mid + 0.5),
        bodyPaint,
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_candles.isEmpty || size.isEmpty || _high == _low) return;

    final canvas = context.canvas;

    canvas.save();
    canvas.clipRect(offset & size);

    final wickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _candleWidth.clamp(0, 1);

    final bodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _candleWidth * 0.8;

    final pricePerPixel = (_high - _low) / size.height;
    final maxVisible = (size.width / _candleWidth).ceil();

    for (int i = 0; i < maxVisible; i++) {
      final candleIndex = i + _index;

      if (candleIndex < 0 || candleIndex >= _candles.length) continue;

      _paintCandle(
        canvas,
        offset,
        i,
        _candles[candleIndex],
        wickPaint,
        bodyPaint,
        pricePerPixel,
      );
    }
    canvas.restore();
  }
}
