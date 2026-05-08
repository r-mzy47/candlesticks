import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/price_scale.dart';
import 'package:flutter/material.dart';

class CandleStickWidget extends LeafRenderObjectWidget {
  final List<Candle> candles;
  final double index;
  final double candleWidth;
  final double high;
  final double low;
  final Color bullColor;
  final Color bearColor;
  final PriceScale priceScale;

  const CandleStickWidget({
    super.key,
    required this.candles,
    required this.index,
    required this.candleWidth,
    required this.low,
    required this.high,
    required this.bearColor,
    required this.bullColor,
    required this.priceScale,
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
      priceScale: priceScale,
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
      ..bearColor = bearColor
      ..priceScale = priceScale;
  }
}

class CandleStickRenderObject extends RenderBox {
  CandleStickRenderObject({
    required List<Candle> candles,
    required double index,
    required double candleWidth,
    required double low,
    required double high,
    required Color bullColor,
    required Color bearColor,
    required PriceScale priceScale,
  })  : _candles = candles,
        _index = index,
        _candleWidth = candleWidth,
        _low = low,
        _high = high,
        _bullColor = bullColor,
        _bearColor = bearColor,
        _priceScale = priceScale,
        _latestClose = candles.isEmpty ? null : candles.first.close,
        _candlesLength = candles.length;

  List<Candle> _candles;
  double _index;
  double _candleWidth;
  double _low;
  double _high;
  Color _bullColor;
  Color _bearColor;
  PriceScale _priceScale;

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

  set index(double value) {
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

  set priceScale(PriceScale value) {
    if (identical(_priceScale, value)) return;

    _priceScale = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  bool _isValidCandle(Candle candle) {
    return _priceScale.isValid(candle.high) &&
        _priceScale.isValid(candle.low) &&
        _priceScale.isValid(candle.open) &&
        _priceScale.isValid(candle.close);
  }

  double _priceToY({
    required double price,
    required Offset offset,
    required double transformedHigh,
    required double transformedValuePerPixel,
  }) {
    return offset.dy +
        (transformedHigh - _priceScale.transform(price)) /
            transformedValuePerPixel;
  }

  void _paintCandle(
    Canvas canvas,
    Offset offset,
    double visibleIndex,
    Candle candle,
    Paint wickPaint,
    Paint bodyPaint,
    double transformedHigh,
    double transformedValuePerPixel,
  ) {
    final color = candle.isBull ? _bullColor : _bearColor;

    wickPaint.color = color;
    bodyPaint.color = color;

    final x = size.width + offset.dx - (visibleIndex + 0.5) * _candleWidth;

    final highY = _priceToY(
      price: candle.high,
      offset: offset,
      transformedHigh: transformedHigh,
      transformedValuePerPixel: transformedValuePerPixel,
    );

    final lowY = _priceToY(
      price: candle.low,
      offset: offset,
      transformedHigh: transformedHigh,
      transformedValuePerPixel: transformedValuePerPixel,
    );

    final openY = _priceToY(
      price: candle.open,
      offset: offset,
      transformedHigh: transformedHigh,
      transformedValuePerPixel: transformedValuePerPixel,
    );

    final closeY = _priceToY(
      price: candle.close,
      offset: offset,
      transformedHigh: transformedHigh,
      transformedValuePerPixel: transformedValuePerPixel,
    );

    if (!highY.isFinite ||
        !lowY.isFinite ||
        !openY.isFinite ||
        !closeY.isFinite) {
      return;
    }

    canvas.drawLine(
      Offset(x, highY),
      Offset(x, lowY),
      wickPaint,
    );

    if (_candleWidth <= 1) return;

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
    if (_candles.isEmpty ||
        size.isEmpty ||
        _candleWidth <= 0 ||
        !_high.isFinite ||
        !_low.isFinite ||
        _high <= _low ||
        !_priceScale.isValid(_high) ||
        !_priceScale.isValid(_low)) {
      return;
    }

    final transformedHigh = _priceScale.transform(_high);
    final transformedLow = _priceScale.transform(_low);

    if (!transformedHigh.isFinite ||
        !transformedLow.isFinite ||
        transformedHigh <= transformedLow) {
      return;
    }

    final transformedValuePerPixel =
        (transformedHigh - transformedLow) / size.height;

    if (!transformedValuePerPixel.isFinite || transformedValuePerPixel <= 0) {
      return;
    }

    final canvas = context.canvas;

    canvas.save();
    canvas.clipRect(offset & size);

    final wickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _candleWidth.clamp(0, 1);

    final bodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _candleWidth * 0.8;

    final maxVisible = (size.width / _candleWidth).ceil();

    final firstVisibleIndex = _index.floor();
    final fractionalOffset = _index - firstVisibleIndex;

    for (int i = 0; i < maxVisible; i++) {
      final candleIndex = i + firstVisibleIndex;

      if (candleIndex < 0 || candleIndex >= _candles.length) continue;

      final candle = _candles[candleIndex];

      if (!_isValidCandle(candle)) continue;

      _paintCandle(
        canvas,
        offset,
        i - fractionalOffset,
        candle,
        wickPaint,
        bodyPaint,
        transformedHigh,
        transformedValuePerPixel,
      );
    }

    canvas.restore();
  }
}
