import 'package:candlesticks/src/models/candle.dart';
import 'package:flutter/material.dart';

class VolumeWidget extends LeafRenderObjectWidget {
  final List<Candle> candles;
  final int index;
  final double barWidth;
  final double high;
  final Color bullColor;
  final Color bearColor;

  const VolumeWidget({
    super.key,
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
      candles: candles,
      index: index,
      barWidth: barWidth,
      high: high,
      bearColor: bearColor,
      bullColor: bullColor,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant VolumeRenderObject renderObject,
  ) {
    renderObject
      ..index = index
      ..candles = candles
      ..barWidth = barWidth
      ..high = high
      ..bearColor = bearColor
      ..bullColor = bullColor;
  }
}

class VolumeRenderObject extends RenderBox {
  VolumeRenderObject({
    required List<Candle> candles,
    required int index,
    required double barWidth,
    required double high,
    required Color bearColor,
    required Color bullColor,
  })  : _candles = candles,
        _index = index,
        _barWidth = barWidth,
        _high = high,
        _bearColor = bearColor,
        _bullColor = bullColor,
        _latestVolume = candles.isEmpty ? null : candles.first.volume,
        _candlesLength = candles.length;

  List<Candle> _candles;
  int _index;
  double _barWidth;
  double _high;
  Color _bearColor;
  Color _bullColor;

  double? _latestVolume;
  int _candlesLength;

  @override
  bool get isRepaintBoundary => true;

  set candles(List<Candle> value) {
    final oldLatestVolume = _latestVolume;
    final oldCandlesLength = _candlesLength;

    final newLatestVolume = value.isEmpty ? null : value.first.volume;
    final newCandlesLength = value.length;

    _candles = value;
    _latestVolume = newLatestVolume;
    _candlesLength = newCandlesLength;

    final latestVolumeChanged = oldLatestVolume != newLatestVolume;
    final candlesLengthChanged = oldCandlesLength != newCandlesLength;

    if (candlesLengthChanged || (_index <= 0 && latestVolumeChanged)) {
      markNeedsPaint();
    }
  }

  set index(int value) {
    if (_index == value) return;

    _index = value;
    markNeedsPaint();
  }

  set barWidth(double value) {
    if (_barWidth == value) return;

    _barWidth = value;
    markNeedsPaint();
  }

  set high(double value) {
    if (_high == value) return;

    _high = value;
    markNeedsPaint();
  }

  set bearColor(Color value) {
    if (_bearColor == value) return;

    _bearColor = value;
    markNeedsPaint();
  }

  set bullColor(Color value) {
    if (_bullColor == value) return;

    _bullColor = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  void _paintBar(
    Canvas canvas,
    Offset offset,
    int visibleIndex,
    Candle candle,
    Paint paint,
    double volumePerPixel,
  ) {
    paint.color = candle.isBull ? _bullColor : _bearColor;

    final x = size.width + offset.dx - (visibleIndex + 0.5) * _barWidth;

    final y = offset.dy + (_high - candle.volume) / volumePerPixel;
    final bottom = offset.dy + size.height;

    canvas.drawLine(
      Offset(x, y),
      Offset(x, bottom),
      paint,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_candles.isEmpty || size.isEmpty || _high == 0 || _barWidth <= 0) {
      return;
    }

    final canvas = context.canvas;

    canvas.save();
    canvas.clipRect(offset & size);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _barWidth * 0.95;

    final volumePerPixel = _high / size.height;
    final maxVisible = (size.width / _barWidth).ceil();

    for (int i = 0; i < maxVisible; i++) {
      final candleIndex = i + _index;

      if (candleIndex < 0 || candleIndex >= _candles.length) continue;

      _paintBar(
        canvas,
        offset,
        i,
        _candles[candleIndex],
        paint,
        volumePerPixel,
      );
    }

    canvas.restore();
  }
}
