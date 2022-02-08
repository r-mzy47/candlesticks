import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/theme/theme_data.dart';
import 'package:candlesticks/src/utils/helper_functions.dart';
import 'package:flutter/material.dart';

class PriceColumn extends StatefulWidget {
  const PriceColumn({
    Key? key,
    required this.low,
    required this.high,
    required this.priceScale,
    required this.width,
    required this.chartHeight,
    required this.lastCandle,
    required this.onScale,
    required this.additionalVerticalPadding,
  }) : super(key: key);

  final double low;
  final double high;
  final double priceScale;
  final double width;
  final double chartHeight;
  final Candle lastCandle;
  final double additionalVerticalPadding;
  final void Function(double) onScale;

  @override
  State<PriceColumn> createState() => _PriceColumnState();
}

class _PriceColumnState extends State<PriceColumn> {
  ScrollController scrollController = new ScrollController();

  double calcutePriceIndicatorTopPadding(
      double chartHeight, double low, double high) {
    return chartHeight +
        10 -
        (widget.lastCandle.close - low) / (high - low) * chartHeight;
  }

  @override
  Widget build(BuildContext context) {
    final double priceTileHeight =
        widget.chartHeight / ((widget.high - widget.low) / widget.priceScale);
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        widget.onScale(details.delta.dy);
      },
      child: AbsorbPointer(
        child: Padding(
          padding:
              EdgeInsets.symmetric(vertical: widget.additionalVerticalPadding),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                top: MAIN_CHART_VERTICAL_PADDING - priceTileHeight / 2,
                height: widget.chartHeight +
                    MAIN_CHART_VERTICAL_PADDING +
                    priceTileHeight / 2,
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
                              color: Theme.of(context).grayColor,
                            ),
                            Expanded(
                              child: Text(
                                "${HelperFunctions.priceToString(widget.high - widget.priceScale * i)}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).scaleNumbersColor,
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
                top: calcutePriceIndicatorTopPadding(
                  widget.chartHeight,
                  widget.low,
                  widget.high,
                ),
                child: Row(
                  children: [
                    Container(
                      color: widget.lastCandle.isBull
                          ? Theme.of(context).primaryGreen
                          : Theme.of(context).primaryRed,
                      child: Center(
                        child: Text(
                          HelperFunctions.priceToString(
                              widget.lastCandle.close),
                          style: TextStyle(
                            color: Theme.of(context).currentPriceColor,
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
      ),
    );
  }
}
