import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/utils/helper_functions.dart';
import 'package:flutter/material.dart';

class PriceColumn extends StatefulWidget {
  const PriceColumn({
    Key? key,
    required this.low,
    required this.high,
    required this.width,
    required this.chartHeight,
    required this.lastCandle,
    required this.onScale,
    required this.style,
  }) : super(key: key);

  final double low;
  final double high;
  final double width;
  final double chartHeight;
  final Candle lastCandle;
  final void Function(double) onScale;
  final CandleSticksStyle style;

  @override
  State<PriceColumn> createState() => _PriceColumnState();
}

class _PriceColumnState extends State<PriceColumn> {
  ScrollController scrollController = new ScrollController();

  double calculatePriceIndicatorTopPadding(
      double chartHeight, double low, double high) {
    return chartHeight +
        10 -
        (widget.lastCandle.close - low) / (high - low) * chartHeight -
        MAIN_CHART_VERTICAL_PADDING;
  }

  @override
  Widget build(BuildContext context) {
    final double priceScale = HelperFunctions.calculatePriceScale(
        widget.chartHeight, widget.high, widget.low);
    final double priceTileHeight =
        widget.chartHeight / ((widget.high - widget.low) / priceScale);
    final double newHigh = (widget.high ~/ priceScale + 1) * priceScale;
    final double top = -priceTileHeight / priceScale * (newHigh - widget.high) +
        MAIN_CHART_VERTICAL_PADDING -
        priceTileHeight / 2;
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        widget.onScale(details.delta.dy);
      },
      child: AbsorbPointer(
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              top: top,
              height:
                  widget.chartHeight + 2 * MAIN_CHART_VERTICAL_PADDING - top,
              width: widget.width,
              child: ListView(
                controller: scrollController,
                children: List<Widget>.generate(20, (i) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: priceTileHeight,
                    width: double.infinity,
                    child: Center(
                      child: Row(
                        children: [
                          Container(
                            width: widget.width - PRICE_BAR_WIDTH,
                            height: 0.05,
                            color: widget.style.borderColor,
                          ),
                          Expanded(
                            child: Text(
                              "${HelperFunctions.priceToString(newHigh - priceScale * i)}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: widget.style.primaryTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              right: 0,
              top: calculatePriceIndicatorTopPadding(
                widget.chartHeight,
                widget.low,
                widget.high,
              ),
              child: Row(
                children: [
                  Container(
                    color: widget.lastCandle.isBull
                        ? widget.style.primaryBull
                        : widget.style.primaryBear,
                    child: Center(
                      child: Text(
                        HelperFunctions.priceToString(widget.lastCandle.close),
                        style: TextStyle(
                          color: widget.style.secondaryTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    width: PRICE_BAR_WIDTH,
                    height: PRICE_INDICATOR_HEIGHT,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
