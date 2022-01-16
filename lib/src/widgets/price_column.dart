import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/theme/color_palette.dart';
import 'package:candlesticks/src/theme/theme_data.dart';
import 'package:flutter/material.dart';

class PriceColumn extends StatelessWidget {
  const PriceColumn({
    Key? key,
    required this.low,
    required this.high,
    required this.priceScale,
    required this.width,
    required this.chartHeight,
  }) : super(key: key);

  final double low;
  final double high;
  final double priceScale;
  final double width;
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    final double priceTileHeight = chartHeight / ((high - low) / priceScale);
    return AnimatedPositioned(
      duration: Duration(milliseconds: 400),
      top: MAIN_CHART_VERTICAL_PADDING - priceTileHeight / 2,
      height: chartHeight +
          2 * MAIN_CHART_VERTICAL_PADDING +
          -MAIN_CHART_VERTICAL_PADDING +
          priceTileHeight / 2,
      width: width,
      child: ListView.builder(
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
                    "-${(high - priceScale * index).toInt()}",
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
    );
  }
}
