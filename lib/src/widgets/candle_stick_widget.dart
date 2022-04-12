import 'package:candlesticks_plus/src/models/candle.dart';
import 'package:candlesticks_plus/src/models/candle_style.dart';
import 'package:candlesticks_plus/src/utils/helper_functions.dart';
import 'package:flutter/material.dart';
import '../models/candle.dart';
import 'dart:math';

class CandleStickWidget extends LeafRenderObjectWidget {
  final List<Candle> candles;
  final int index;
  final double candleWidth;
  final double high;
  final double low;
  final CandleStyle? candleStyle;
  final bool ma7, ma25, ma99;

  CandleStickWidget({
    required this.candles,
    required this.index,
    required this.candleWidth,
    required this.low,
    required this.high,
    this.candleStyle,
    this.ma7 = true,
    this.ma25 = true,
    this.ma99 = true,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return CandleStickRenderObject(candles, index, candleWidth, low, high, candleStyle, ma7, ma25, ma99);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    CandleStickRenderObject candlestickRenderObject = renderObject as CandleStickRenderObject;

    if (index <= 0 && candlestickRenderObject._close != candles[0].close) {
      candlestickRenderObject._candles = candles;
      candlestickRenderObject._index = index;
      candlestickRenderObject._candleWidth = candleWidth;
      candlestickRenderObject._high = high;
      candlestickRenderObject._low = low;
      candlestickRenderObject._candleStyle = candleStyle;
      candlestickRenderObject.markNeedsPaint();
    } else if (candlestickRenderObject._index != index ||
        candlestickRenderObject._candleWidth != candleWidth ||
        candlestickRenderObject._high != high ||
        candlestickRenderObject._low != low) {
      candlestickRenderObject._candles = candles;
      candlestickRenderObject._index = index;
      candlestickRenderObject._candleWidth = candleWidth;
      candlestickRenderObject._high = high;
      candlestickRenderObject._low = low;
      candlestickRenderObject._candleStyle = candleStyle;
      candlestickRenderObject.markNeedsPaint();
    }
    super.updateRenderObject(context, renderObject);
  }
}

class CandleStickRenderObject extends RenderBox {
  late List<Candle> _candles;
  late int _index;
  late double _candleWidth;
  late double _low;
  late double _high;
  late double _close;
  late CandleStyle? _candleStyle;
  late bool _ma7, _ma25, _ma99;

  CandleStickRenderObject(List<Candle> candles, int index, double candleWidth, double low, double high,
      CandleStyle? candleStyle, bool ma7, bool ma25, bool ma99) {
    _candles = candles;
    _index = index;
    _candleWidth = candleWidth;
    _low = low;
    _high = high;
    _candleStyle = candleStyle;
    _ma7 = ma7;
    _ma25 = ma25;
    _ma99 = ma99;
  }

  /// set size as large as possible
  @override
  void performLayout() {
    size = Size(constraints.maxWidth, constraints.maxHeight);
  }

  /// draws a single candle
  void paintCandle(PaintingContext context, Offset offset, int index, Candle candle, double range) {
    Color color = _candleStyle != null
        ? (candle.isBull ? _candleStyle!.bullColor : _candleStyle!.bearColor)
        : (candle.isBull ? Colors.green : Colors.red);

    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    double x = size.width + offset.dx - (index + 0.5) * _candleWidth;

    context.canvas.drawLine(
      Offset(x, offset.dy + (_high - candle.high) / range),
      Offset(x, offset.dy + (_high - candle.low) / range),
      paint,
    );

    final double openCandleY = offset.dy + (_high - candle.open) / range;
    final double closeCandleY = offset.dy + (_high - candle.close) / range;

    if ((openCandleY - closeCandleY).abs() > 1) {
      context.canvas.drawLine(
        Offset(x, openCandleY),
        Offset(x, closeCandleY),
        paint..strokeWidth = _candleWidth - 1,
      );
    } else {
      // if the candle body is too small
      final double mid = (closeCandleY + openCandleY) / 2;
      context.canvas.drawLine(
        Offset(x, mid - 0.5),
        Offset(x, mid + 0.5),
        paint..strokeWidth = _candleWidth - 1,
      );
    }
  }

  /// draw MA7
  // Offset? paintMA7(Offset offset, int index, Candle candle) {
  //   if (_candles.length - 7 <= _index + index) return null;
  //   double range = (_high - _low) / size.height;
  //   double x = size.width + offset.dx - (index + 0.5) * _candleWidth;
  //   final currentIndex = _index + index;
  //   final list = _candles.sublist(currentIndex, currentIndex + 6).map((e) => e.close);
  //   double y = (list.fold<double>(0, (double p, double c) => p + c)) / list.length;
  //   return Offset(x, offset.dy + (_high - y) / range);
  // }

  /// draw MA25
  // Offset? paintMA25(Offset offset, int index, Candle candle) {
  //   if (_candles.length - 25 <= _index + index) return null;
  //
  //   double range = (_high - _low) / size.height;
  //   double x = size.width + offset.dx - (index + 0.5) * _candleWidth;
  //   final currentIndex = _index + index;
  //   final list = _candles.sublist(currentIndex, currentIndex + 24).map((e) => e.close);
  //   double y = (list.fold<double>(0, (double p, double c) => p + c)) / list.length;
  //
  //   return Offset(x, offset.dy + (_high - y) / range);
  // }

  /// draw MA99
  // Offset? paintMA99(Offset offset, int index, Candle candle) {
  //   if (_candles.length - 99 <= _index + index) return null;
  //
  //   double range = (_high - _low) / size.height;
  //   double x = size.width + offset.dx - (index + 0.5) * _candleWidth;
  //   final currentIndex = _index + index;
  //   final list = _candles.sublist(currentIndex, currentIndex + 98).map((e) => e.close);
  //   double y = (list.fold<double>(0, (double p, double c) => p + c)) / list.length;
  //
  //   return Offset(x, offset.dy + (_high - y) / range);
  // }

  void paintMA(Canvas canvas, List<Offset> points, Color color) {
    if (points.isEmpty) return;

    gradient(Offset a, Offset b) {
      return (b.dy - a.dy) / (b.dx - a.dx);
    }

    Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    var m = 0.0;
    var dx1 = 0.0;
    var dy1 = 0.0;

    var preP = points[0];

    for (var i = 1; i < points.length; i++) {
      var curP = points[i];
      var dx2 = 0.0, dy2 = 0.0;
      if (i == points.length - 2) {
        Offset nexP = points[i + 1];
        m = gradient(preP, nexP);
        dx2 = (nexP.dx - curP.dx) * -0.3;
        dy2 = dx2 * m * 0.6;
      } else {
        dx2 = 0;
        dy2 = 0;
      }

      path.cubicTo(preP.dx - dx1, preP.dy - dy1, curP.dx + dx2, curP.dy + dy2, curP.dx, curP.dy);

      dx1 = dx2;
      dy1 = dy2;
      preP = curP;
    }

    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    double range = (_high - _low) / size.height;
    // List<Offset> maPoints7 = [];
    // List<Offset> maPoints25 = [];
    // List<Offset> maPoints99 = [];

    List<Map<String, dynamic>> visibleCandles = [];
    for (int i = 0; (i + 1) * _candleWidth < size.width; i++) {
      if (i + _index >= _candles.length || i + _index < 0) continue;
      var candle = _candles[i + _index];
      visibleCandles.add({'c': candle, 'i': i});

      paintCandle(context, offset, i, candle, range);

      // if (_ma7) {
      //   final maOffset7 = paintMA7(offset, i, candle);
      //   if (maOffset7 != null) maPoints7.add(maOffset7);
      // }

      // if (_ma25) {
      //   final maOffset25 = paintMA25(offset, i, candle);
      //   if (maOffset25 != null) maPoints25.add(maOffset25);
      // }

      // if (_ma99) {
      //   final maOffset99 = paintMA99(offset, i, candle);
      //   if (maOffset99 != null) maPoints99.add(maOffset99);
      // }
    }

    List<Candle> inArea = visibleCandles.map<Candle>((e) => e['c']).toList();

    paintMinLowMaxHigh(context, inArea, offset, range);

    if (_ma7)
      paintMA(
          context.canvas,
          visibleCandles
              .where((e) => (e['c'] as Candle).ma7 != null)
              .map((e) =>
              Offset(size.width + offset.dx - (e['i'] + 0.5) * _candleWidth, offset.dy + (_high - (e['c'] as Candle).ma7!) / range))
              .toList(),
          Colors.orangeAccent);

    if (_ma25)
      paintMA(
          context.canvas,
          visibleCandles
              .where((e) => (e['c'] as Candle).ma25 != null)
              .map((e) =>
              Offset(size.width + offset.dx - (e['i'] + 0.5) * _candleWidth, offset.dy + (_high - (e['c'] as Candle).ma25!) / range))
              .toList(),
          Colors.purpleAccent);

    if (_ma99)
      paintMA(
          context.canvas,
          visibleCandles
          .where((e) => (e['c'] as Candle).ma99 != null)
              .map((e) =>
              Offset(size.width + offset.dx - (e['i'] + 0.5) * _candleWidth, offset.dy + (_high - (e['c'] as Candle).ma99!) / range))
              .toList(),
          Colors.blueAccent);
    // if (_ma25) paintMA(context.canvas, maPoints7, Colors.orangeAccent);
    // if (_ma25) paintMA(context.canvas, maPoints25, Colors.purpleAccent);
    // if (_ma99) paintMA(context.canvas, maPoints99, Colors.blueAccent);

    _close = _candles[0].close;
    context.canvas.save();
    context.canvas.restore();
  }

  void paintMinLowMaxHigh(PaintingContext context, List<Candle> inArea, Offset offset, double range) {
    final minLow = inArea.map((e) => e.low).reduce(min);
    final maxHigh = inArea.map((e) => e.high).reduce(max);

    final minLowX =
        size.width + offset.dx - (_candles.indexWhere((e) => e.low == minLow) - _index + 0.5) * _candleWidth;
    final minLowY = offset.dy + (_high - minLow) / range;
    context.canvas.drawLine(
        Offset(
          minLowX <= size.width / 2 ? minLowX + (20) : minLowX - (20),
          minLowY,
        ),
        Offset(minLowX, minLowY),
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill);

    final maxHighX =
        size.width + offset.dx - (_candles.indexWhere((e) => e.high == maxHigh) - _index + 0.5) * _candleWidth;
    final maxHighY = offset.dy + ((_high - maxHigh) / range);
    context.canvas.drawLine(
        Offset(
          maxHighX <= size.width / 2 ? maxHighX + (20) : maxHighX - (20),
          maxHighY,
        ),
        Offset(maxHighX, maxHighY),
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill);

    TextPainter lowTp = TextPainter(
        text: TextSpan(style: TextStyle(fontSize: 10), text: HelperFunctions.priceToString(minLow)),
        textDirection: TextDirection.ltr);
    lowTp.layout();
    lowTp.paint(
        context.canvas,
        Offset(
            (minLowX <= size.width / 2 ? minLowX + 20 : minLowX - 20) +
                (minLowX <= size.width / 2 ? 4 : (-lowTp.width - 4)),
            minLowY - lowTp.height / 2));

    TextPainter highTp = TextPainter(
        text: TextSpan(style: TextStyle(fontSize: 10), text: HelperFunctions.priceToString(maxHigh)),
        textDirection: TextDirection.ltr);
    highTp.layout();
    highTp.paint(
        context.canvas,
        Offset(
            (maxHighX <= size.width / 2 ? maxHighX + 20 : maxHighX - 20) +
                (maxHighX <= size.width / 2 ? 4 : (-highTp.width - 4)),
            maxHighY - highTp.height / 2));
  }
}
