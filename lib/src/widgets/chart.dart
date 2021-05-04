import 'dart:math';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/price_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/candle.dart';
import 'package:candlesticks/src/constant/scales.dart';

/// This widget manages gestures
/// Calculates the highest and lowest price of visible candles.
/// Updates right-hand side numbers.
/// And pass values down to [CandleStickWidget].
class Chart extends StatelessWidget {
  /// onScaleUpdate callback
  /// called when user scales chart using buttons or scale gesture
  final Function onScaleUpdate;

  /// onHorizontalDragUpdate
  /// callback calls when user scrolls horizontally along the chart
  final Function onHorizontalDragUpdate;

  /// candleWidth controls the width of the single candles.
  /// range: [2...10]
  final double candleWidth;

  /// list of all candles to display in chart
  final List<Candle> candles;

  /// index of the newest candle to be displayed
  /// changes when user scrolls along the chart
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
        double range = high - low;
        double tileHeight = 0;
        int scaleIndex = 0;
        for (int i = 0; i < scales.length; i++) {
          if (range / scales[i] > 40) {
            tileHeight = range / scales[i];
            scaleIndex = i;
          }
        }
        high =
            ((high ~/ scales[scaleIndex] + 1) * scales[scaleIndex]).toDouble();
        low = ((low ~/ scales[scaleIndex]) * scales[scaleIndex]).toDouble();
        return Container(
          color: Color.fromARGB(255, 25, 27, 32),
          child: Stack(
            children: [
              PriceColumn(
                tileHeight: tileHeight,
                high: high,
                scaleIndex: scaleIndex,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
              Row(
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
                  SizedBox(
                    width: 50,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
