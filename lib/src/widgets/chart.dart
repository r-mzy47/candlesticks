import 'dart:math';
import 'package:candlesticks/src/theme/color_palette.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/price_column.dart';
import 'package:candlesticks/src/widgets/time_row.dart';
import 'package:candlesticks/src/widgets/volume_widget.dart';
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

  final ScrollController scrollController;

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
    required this.scrollController,
  });

  double log10(num x) => log(x) / ln10;

  double getRoof(double number) {
    int log = log10(number).floor();
    return (number ~/ pow(10, log) + 1) * pow(10, log).toDouble();
  }

  String priceToString(double price) {
    int log = log10(price).floor();
    if (log > 9)
      return "${price ~/ 1000000000}B";
    else if (log > 6)
      return "${price ~/ 1000000}M";
    else if (log > 3)
      return "${price ~/ 1000}K";
    else
      return "$price";
  }

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
        double tileHeight = 0;
        int scaleIndex = 0;
        final maxHeight = constraints.maxHeight - 20;
        double chartHeight = maxHeight * 3 / 4 - 40;
        for (int i = 0; i < scales.length; i++) {
          double newHigh = ((high ~/ scales[i] + 1) * scales[i]).toDouble();
          double newLow = ((low ~/ scales[i]) * scales[i]).toDouble();
          double range = newHigh - newLow;
          if (chartHeight / (range / scales[i]) > 30) {
            tileHeight = chartHeight / (range / scales[i]);
            scaleIndex = i;
            break;
          }
        }

        high =
            ((high ~/ scales[scaleIndex] + 1) * scales[scaleIndex]).toDouble();
        low = ((low ~/ scales[scaleIndex]) * scales[scaleIndex]).toDouble();

        double volumeHigh = 0;
        for (int i = 0;
            (i + 1) * candleWidth < constraints.maxWidth - 50;
            i++) {
          if (i + index >= candles.length || i + index < 0) continue;
          volumeHigh = max(candles[i + index].volume, volumeHigh);
        }

        return TweenAnimationBuilder(
          tween: Tween(begin: low, end: high),
          duration: Duration(milliseconds: 200),
          builder: (context, high, _) {
            return TweenAnimationBuilder(
              tween: Tween(begin: low, end: low),
              duration: Duration(milliseconds: 200),
              builder: (context, low, _) {
                return Container(
                  color: ColorPalette.darkBlue,
                  child: Stack(
                    children: [
                      TimeRow(
                        candles: candles,
                        scrollController: scrollController,
                        candleWidth: candleWidth,
                      ),
                      Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                PriceColumn(
                                  tileHeight: tileHeight,
                                  high: high as double,
                                  scaleIndex: scaleIndex,
                                  width: constraints.maxWidth,
                                  height: maxHeight * 3 / 4,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onScaleUpdate: (ScaleUpdateDetails
                                            scaleUpdateDetails) {
                                          if (scaleUpdateDetails.scale == 1.0) {
                                            return;
                                          }
                                          onScaleUpdate(
                                              scaleUpdateDetails.scale);
                                        },
                                        onHorizontalDragUpdate: (detais) {
                                          double x = detais.delta.dx;
                                          onHorizontalDragUpdate(x);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.symmetric(
                                              vertical: BorderSide(
                                                color: Color.fromARGB(
                                                    255, 132, 142, 156),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20),
                                            child: CandleStickWidget(
                                              candles: candles,
                                              candleWidth: candleWidth,
                                              index: index,
                                              high: high,
                                              low: low as double,
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
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.symmetric(
                                        vertical: BorderSide(
                                          color: Color.fromARGB(
                                              255, 132, 142, 156),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: VolumeWidget(
                                        candles: candles,
                                        barWidth: candleWidth,
                                        index: index,
                                        high: getRoof(volumeHigh),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "-${priceToString(getRoof(volumeHigh))}",
                                        style: TextStyle(
                                          color: Color.fromARGB(
                                              255, 132, 142, 156),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  width: 50,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
