import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/data/minmax_cache.dart';
import 'package:candlesticks/src/main.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/models/price_scale.dart';
import 'package:candlesticks/src/widgets/axis/value_axis.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:candlesticks/src/widgets/gesture_handler/gesture_handler.dart';
import 'package:candlesticks/src/widgets/high_low_animator.dart';
import 'package:candlesticks/src/widgets/hovered_candle_info_bar.dart';
import 'package:candlesticks/src/widgets/volume_widget.dart';
import 'package:flutter/material.dart';

import '../models/candle.dart';

class MainChartPane extends StatefulWidget {
  const MainChartPane({
    super.key,
    required this.candles,
    required this.controller,
    required this.viewPort,
    required this.onCrosshairXChange,
    this.crosshairXFromRight,
  });

  final List<Candle> candles;

  final CandlesticksController controller;

  final CandlesticksViewport viewPort;

  final Function(double?) onCrosshairXChange;

  final double? crosshairXFromRight;

  @override
  State<MainChartPane> createState() => _CandleSticksChartState();
}

class _CandleSticksChartState extends State<MainChartPane> {
  final cache = MinMaxCache();
  PriceScale priceScale = log10PriceScale;

  @override
  void initState() {
    super.initState();
    cache.updateCandles(widget.candles);
  }

  @override
  void didUpdateWidget(covariant MainChartPane oldWidget) {
    super.didUpdateWidget(oldWidget);

    cache.updateCandles(widget.candles);
  }

  void onPriceScaleToggle() {
    setState(() {
      if (priceScale == log10PriceScale) {
        priceScale = linearPriceScale;
      } else {
        priceScale = log10PriceScale;
      }
    });
  }

  int _nearestCandleIndexAtX(double xFromRight) {
    if (widget.candles.isEmpty) return 0;

    return (widget.viewPort.scrollIndex +
            xFromRight / widget.viewPort.candleWidth -
            0.5)
        .round()
        .clamp(0, widget.candles.length - 1)
        .toInt();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;

        final double chartWidth = maxWidth - PRICE_BAR_WIDTH;
        final double volumeBarsHeight = maxHeight * 0.2;

        final int candlesStartIndex =
            widget.controller.firstVisibleCandleIndexFor(widget.viewPort);

        final int candlesEndIndex =
            widget.controller.lastVisibleCandleIndexFor(widget.viewPort);

        final List<Candle> inRangeCandles = widget.candles
            .getRange(candlesStartIndex, candlesEndIndex + 1)
            .toList();

        final RangeMinMax minMax = cache.queryByTime(
          inRangeCandles.first.date,
          inRangeCandles.last.date,
        );

        double candlesHighPrice = minMax.maxHigh;
        double candlesLowPrice = minMax.minLow;

        final paddedPrice = priceScale.addPadding(
          low: candlesLowPrice,
          high: candlesHighPrice,
        );

        candlesHighPrice = paddedPrice.high;
        candlesLowPrice = paddedPrice.low;

        if (candlesHighPrice == candlesLowPrice) {
          candlesHighPrice += 10;
          candlesLowPrice -= 10;
        }

        final CandleSticksStyle style = CandleSticksStyleProvider.of(context);

        return GestureHandler(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          controller: widget.controller,
          candlesHighPrice: candlesHighPrice,
          candlesLowPrice: candlesLowPrice,
          viewPort: widget.viewPort,
          onCrosshairXChange: widget.onCrosshairXChange,
          priceScale: priceScale,
          onPriceScaleToggle: onPriceScaleToggle,
          builder: (
            BuildContext context,
            double newHigh,
            double newLow,
            double? crosshairY,
            bool isPriceScaled,
          ) {
            return Stack(
              children: [
                ValueAxis(
                  low: newLow,
                  high: newHigh,
                  width: maxWidth,
                  crosshairY: crosshairY,
                  chartHeight: maxHeight,
                  lastCandle: widget.candles[candlesStartIndex],
                  priceScale: priceScale,
                ),
                Positioned(
                  bottom: 0,
                  height: volumeBarsHeight,
                  width: chartWidth,
                  child: VolumeWidget(
                    candles: widget.candles,
                    barWidth: widget.viewPort.candleWidth,
                    index: widget.viewPort.scrollIndex,
                    high: minMax.maxVolume,
                    bearColor: style.volumeBearColor,
                    bullColor: style.volumeBullColor,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  height: maxHeight,
                  width: chartWidth,
                  child: HighLowAnimator(
                    candlesHighPrice: newHigh,
                    candlesLowPrice: newLow,
                    diableAnimation: isPriceScaled,
                    builder: (BuildContext context, double high, double low) {
                      return CandleStickWidget(
                        candles: widget.candles,
                        candleWidth: widget.viewPort.candleWidth,
                        index: widget.viewPort.scrollIndex,
                        high: high,
                        low: low,
                        bearColor: style.candleBearColor,
                        bullColor: style.candleBullColor,
                        priceScale: priceScale,
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 12,
                  child: HoveredCandleInfoBar(
                    currentCandle: widget.crosshairXFromRight == null
                        ? null
                        : widget.candles[_nearestCandleIndexAtX(
                            widget.crosshairXFromRight!,
                          )],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
