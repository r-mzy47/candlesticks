import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/utils/helper_functions.dart';
import 'package:candlesticks/src/widgets/dash_line_painter.dart';
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
    required this.volumeHigh,
    this.mouseHoverY,
  }) : super(key: key);

  final double low;
  final double high;
  final double width;
  final double chartHeight;
  final Candle lastCandle;
  final double volumeHigh;
  final double? mouseHoverY;
  final void Function(double) onScale;
  final CandleSticksStyle style;

  @override
  State<PriceColumn> createState() => _PriceColumnState();
}

class _PriceColumnState extends State<PriceColumn> {
  ScrollController scrollController = new ScrollController();

  double calculatePriceIndicatorTopPadding(
      double chartHeight, double low, double high) {
    return chartHeight -
        (widget.lastCandle.close - low) / (high - low) * chartHeight -
        10;
  }

  String calculateHoverdNumber(double mouseHoverY, double low, double high,
      double chartHeight, double volumeHigh) {
    return mouseHoverY < chartHeight
        ? HelperFunctions.priceToString(
            high - (mouseHoverY) / chartHeight * (high - low))
        : HelperFunctions.addMetricPrefix(HelperFunctions.getRoof(volumeHigh) *
            (1 - (mouseHoverY - chartHeight - 10) / (chartHeight * 0.33 - 10)));
  }

  @override
  Widget build(BuildContext context) {
    final double priceScale = HelperFunctions.calculatePriceScale(
        widget.chartHeight, widget.high, widget.low);
    final double priceTileHeight =
        widget.chartHeight / ((widget.high - widget.low) / priceScale);
    final double newHigh = (widget.high ~/ priceScale + 1) * priceScale;
    final double top = -priceTileHeight / priceScale * (newHigh - widget.high) -
        priceTileHeight / 2;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  widget.onScale(details.delta.dy);
                },
                child: AbsorbPointer(
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: Duration(milliseconds: 300),
                        top: top,
                        height: widget.chartHeight - top,
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
                                      height: 1,
                                      color: widget.style.gridColor,
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
                                  HelperFunctions.priceToString(
                                      widget.lastCandle.close),
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
              ),
            ),
            Expanded(
              flex: 1,
              child: SizedBox(
                width: PRICE_BAR_WIDTH,
                child: Text(
                  "-${HelperFunctions.addMetricPrefix(HelperFunctions.getRoof(widget.volumeHigh))}",
                  style: TextStyle(
                    color: widget.style.borderColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        widget.mouseHoverY != null
            ? Positioned(
                top: widget.mouseHoverY! - 10,
                child: Row(
                  children: [
                    CustomPaint(
                      size: Size(widget.width - PRICE_BAR_WIDTH, 1),
                      painter: DashLinePainter(
                        direction: Axis.horizontal,
                        color: widget.style.borderColor,
                      ),
                    ),
                    Container(
                      color: widget.style.hoverIndicatorBackgroundColor,
                      child: Center(
                        child: Text(
                          calculateHoverdNumber(
                            widget.mouseHoverY!,
                            widget.low,
                            widget.high,
                            widget.chartHeight,
                            widget.volumeHigh,
                          ),
                          style: TextStyle(
                            color: widget.style.secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      width: PRICE_BAR_WIDTH,
                      height: 20,
                    ),
                  ],
                ),
              )
            : Container(),
      ],
    );
  }
}
