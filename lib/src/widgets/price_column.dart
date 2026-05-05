import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/price_scale.dart';
import 'package:candlesticks/src/utils/helper_functions.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:candlesticks/src/widgets/dash_line_painter.dart';
import 'package:flutter/material.dart';

class PriceColumn extends StatefulWidget {
  const PriceColumn({
    super.key,
    required this.low,
    required this.high,
    required this.width,
    required this.chartHeight,
    required this.lastCandle,
    this.mouseHoverY,
    required this.priceScale,
  });

  final double low;
  final double high;
  final double width;
  final double chartHeight;
  final Candle lastCandle;
  final double? mouseHoverY;
  final PriceScale priceScale;

  @override
  State<PriceColumn> createState() => _PriceColumnState();
}

class _PriceColumnState extends State<PriceColumn> {
  final ScrollController scrollController = ScrollController();

  double _priceToY(double price) {
    final transformedHigh = widget.priceScale.transform(widget.high);
    final transformedLow = widget.priceScale.transform(widget.low);
    final transformedPrice = widget.priceScale.transform(price);

    return widget.chartHeight -
        ((transformedPrice - transformedLow) /
                (transformedHigh - transformedLow)) *
            widget.chartHeight;
  }

  double _yToPrice(double y) {
    final transformedHigh = widget.priceScale.transform(widget.high);
    final transformedLow = widget.priceScale.transform(widget.low);

    final transformedPrice = transformedHigh -
        (y / widget.chartHeight) * (transformedHigh - transformedLow);

    return widget.priceScale.inverse(transformedPrice);
  }

  double calculatePriceIndicatorTopPadding() {
    return _priceToY(widget.lastCandle.close) - 10;
  }

  String calculateHoveredNumber(double mouseHoverY) {
    return HelperFunctions.priceToString(_yToPrice(mouseHoverY));
  }

  @override
  Widget build(BuildContext context) {
    final style = CandleSticksStyleProvider.of(context);

    if (widget.chartHeight <= 0 ||
        widget.high == widget.low ||
        !widget.priceScale.isValid(widget.high) ||
        !widget.priceScale.isValid(widget.low) ||
        !widget.priceScale.isValid(widget.lastCandle.close)) {
      return const SizedBox.shrink();
    }

    final transformedHigh = widget.priceScale.transform(widget.high);
    final transformedLow = widget.priceScale.transform(widget.low);

    final transformedPriceScale = HelperFunctions.calculatePriceScale(
      widget.chartHeight,
      transformedHigh,
      transformedLow,
    );

    final priceTileHeight = widget.chartHeight /
        ((transformedHigh - transformedLow) / transformedPriceScale);

    final newTransformedHigh =
        (transformedHigh ~/ transformedPriceScale + 1) * transformedPriceScale;

    final top = -priceTileHeight /
            transformedPriceScale *
            (newTransformedHigh - transformedHigh) -
        priceTileHeight / 2;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: AbsorbPointer(
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      top: top,
                      height: widget.chartHeight - top,
                      width: widget.width,
                      child: ListView(
                        controller: scrollController,
                        children: List<Widget>.generate(
                          widget.chartHeight ~/ MIN_PRICETILE_HEIGHT + 1,
                          (i) {
                            final transformedPrice =
                                newTransformedHigh - transformedPriceScale * i;

                            final price =
                                widget.priceScale.inverse(transformedPrice);

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: priceTileHeight,
                              width: double.infinity,
                              child: Center(
                                child: Row(
                                  children: [
                                    Container(
                                      width: widget.width - PRICE_BAR_WIDTH,
                                      height: 1,
                                      color: style.gridColor,
                                    ),
                                    Expanded(
                                      child: Text(
                                        HelperFunctions.priceToString(price),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: style.primaryTextColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      right: 0,
                      top: calculatePriceIndicatorTopPadding(),
                      child: Container(
                        color: widget.lastCandle.isBull
                            ? style.primaryBull
                            : style.primaryBear,
                        width: PRICE_BAR_WIDTH,
                        height: PRICE_INDICATOR_HEIGHT,
                        child: Center(
                          child: Text(
                            HelperFunctions.priceToString(
                                widget.lastCandle.close),
                            style: TextStyle(
                              color: style.secondaryTextColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (widget.mouseHoverY != null)
          Positioned(
            top: widget.mouseHoverY! - 10,
            child: Row(
              children: [
                CustomPaint(
                  size: Size(widget.width - PRICE_BAR_WIDTH, 1),
                  painter: DashLinePainter(
                    direction: Axis.horizontal,
                    color: style.borderColor,
                  ),
                ),
                Container(
                  color: style.hoverIndicatorBackgroundColor,
                  width: PRICE_BAR_WIDTH,
                  height: 20,
                  child: Center(
                    child: Text(
                      calculateHoveredNumber(widget.mouseHoverY!),
                      style: TextStyle(
                        color: style.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
