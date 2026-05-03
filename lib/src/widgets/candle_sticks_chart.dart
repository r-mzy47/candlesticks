import 'dart:math';

import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/data/minmax_cache.dart';
import 'package:candlesticks/src/main.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/models/price_scale.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:candlesticks/src/widgets/gesture_handler.dart';
import 'package:candlesticks/src/widgets/high_low_animator.dart';
import 'package:candlesticks/src/widgets/price_column.dart' hide PriceScale;
import 'package:candlesticks/src/widgets/top_panel.dart';
import 'package:candlesticks/src/widgets/volume_widget.dart';
import 'package:flutter/material.dart';

import '../models/candle.dart';

class CandleSticksChart extends StatefulWidget {
  const CandleSticksChart({
    super.key,
    required this.candles,
    required this.chartAdjust,
    required this.controller,
    required this.viewPort,
    required this.onMouseHoverXChange,
    this.hoveredCandleIndex,
  });

  final List<Candle> candles;

  final ChartAdjust chartAdjust;

  final CandlesticksController controller;

  final CandlesticksViewport viewPort;

  final Function(double?) onMouseHoverXChange;

  final int? hoveredCandleIndex;

  @override
  State<CandleSticksChart> createState() => _CandleSticksChartState();
}

class _CandleSticksChartState extends State<CandleSticksChart> {
  final cache = MinMaxCache();
  PriceScale priceScale = log10PriceScale;

  @override
  void initState() {
    cache.updateCandles(widget.candles);
    super.initState();
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

  @override
  void didUpdateWidget(covariant CandleSticksChart oldWidget) {
    cache.updateCandles(widget.candles);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;

        final double volumeBarsHeight = maxHeight * 0.2;

        final int candlesStartIndex = max(widget.viewPort.scrollIndex, 0);
        final int candlesEndIndex = min(
          maxWidth ~/ widget.viewPort.candleWidth + widget.viewPort.scrollIndex,
          widget.candles.length - 1,
        );
        List<Candle> inRangeCandles = widget.candles
            .getRange(candlesStartIndex, candlesEndIndex + 1)
            .toList();

        late RangeMinMax minMax;
        if (widget.chartAdjust == ChartAdjust.visibleRange) {
          minMax = cache.queryByTime(
              inRangeCandles.first.date, inRangeCandles.last.date);
        } else {
          minMax = cache.queryByTime(
              widget.candles.first.date, widget.candles.last.date);
        }

        double candlesHighPrice = minMax.maxHigh;
        double candlesLowPrice = minMax.minLow;
        final paddedPrice = priceScale.addPadding(
            low: candlesLowPrice, high: candlesHighPrice); // todo: refactor it
        candlesHighPrice = paddedPrice.high;
        candlesLowPrice = paddedPrice.low;

        if (candlesHighPrice == candlesLowPrice) {
          candlesHighPrice += 10;
          candlesLowPrice -= 10;
        }

        // calculate highest volume. todo: move this to MinMaxCache
        double volumeHigh = inRangeCandles.map((e) => e.volume).reduce(max);

        CandleSticksStyle style = CandleSticksStyleProvider.of(context);

        return GestureHandler(
          candlesCount: widget.candles.length,
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          controller: widget.controller,
          candlesHighPrice: candlesHighPrice,
          candlesLowPrice: candlesLowPrice,
          viewPort: widget.viewPort,
          onMouseHoverXChange: widget.onMouseHoverXChange,
          priceScale: priceScale,
          onPriceScaleToggle: onPriceScaleToggle,
          builder: (
            BuildContext context,
            double newHigh,
            double newLow,
            double? mouseHoverY,
            bool isPriceScaled,
          ) {
            return Stack(
              children: [
                PriceColumn(
                  low: newLow,
                  high: newHigh,
                  width: maxWidth,
                  mouseHoverY: mouseHoverY,
                  chartHeight: maxHeight,
                  lastCandle:
                      widget.candles[max(widget.viewPort.scrollIndex, 0)],
                  priceScale: priceScale,
                ),
                Positioned(
                  bottom: 0,
                  height: volumeBarsHeight,
                  width: maxWidth - PRICE_BAR_WIDTH,
                  child: VolumeWidget(
                    candles: widget.candles,
                    barWidth: widget.viewPort.candleWidth,
                    index: widget.viewPort.scrollIndex,
                    high: volumeHigh,
                    bearColor: style.secondaryBear,
                    bullColor: style.secondaryBull,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  height: maxHeight,
                  width: maxWidth - PRICE_BAR_WIDTH,
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
                        bearColor: style.primaryBear,
                        bullColor: style.primaryBull,
                        priceScale: priceScale,
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 12,
                  child: TopPanel(
                    currentCandle: widget.hoveredCandleIndex != null
                        ? widget.candles[widget.hoveredCandleIndex!]
                        : null,
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
