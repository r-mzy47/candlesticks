import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/theme/theme_data.dart';
import 'package:candlesticks/src/utils/helper_functions.dart';
import 'package:flutter/material.dart';

class PriceColumn extends StatelessWidget {
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

  double calcutePriceIndicatorTopPadding(
      double chartHeight, double low, double high) {
    return chartHeight +
        10 -
        (lastCandle.close - low) / (high - low) * chartHeight;
  }

  @override
  Widget build(BuildContext context) {
    final double priceTileHeight = chartHeight / ((high - low) / priceScale);
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        onScale(details.delta.dy);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: additionalVerticalPadding),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: Duration(milliseconds: 400),
              top: MAIN_CHART_VERTICAL_PADDING - priceTileHeight / 2,
              height: chartHeight +
                  MAIN_CHART_VERTICAL_PADDING +
                  priceTileHeight / 2,
              width: width,
              child: ListView.builder(
                key: Key("priceColumnListBuilder"),
                physics: NeverScrollableScrollPhysics(),
                itemCount: 100,
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    height: priceTileHeight,
                    width: double.infinity,
                    child: Center(
                      child: Row(
                        children: [
                          Container(
                            width: width - PRICE_BAR_WIDTH,
                            height: 0.05,
                            color: Theme.of(context).grayColor,
                          ),
                          Text(
                            "-${HelperFunctions.priceToString(high - priceScale * index)}",
                            style: TextStyle(
                              color: Theme.of(context).scaleNumbersColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              right: 0,
              top: calcutePriceIndicatorTopPadding(
                chartHeight,
                low,
                high,
              ),
              child: Row(
                children: [
                  Container(
                    color: lastCandle.isBull
                        ? Theme.of(context).primaryGreen
                        : Theme.of(context).primaryRed,
                    child: Center(
                      child: Text(
                        HelperFunctions.priceToString(lastCandle.close),
                        style: TextStyle(
                          color: Theme.of(context).currentPriceColor,
                          fontSize: 12,
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
