import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:flutter/material.dart';

/// Transparent hit‑box on the right‑edge of the main pane.
/// • still forwards the vertical‑drag so you can manual‑scale  
/// • the static price scale is gone  
/// • the coloured last‑price chip is optional
class PriceColumn extends StatelessWidget {
  const PriceColumn({
    super.key,
    required this.low,
    required this.high,
    required this.chartHeight,
    required this.lastCandle,
    required this.onScale,
    required this.style,
    this.showLastPrice = true,
  });

  final double low;
  final double high;
  final double chartHeight;
  final Candle lastCandle;
  final void Function(double) onScale;
  final CandleSticksStyle style;
  final bool showLastPrice;

  // where to position the chip vertically
  double _chipTop() => chartHeight +
      10 -
      (lastCandle.close - low) / (high - low) * chartHeight -
      MAIN_CHART_VERTICAL_PADDING;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // vertical‑drag → manual scaling
      onVerticalDragUpdate: (d) => onScale(d.delta.dy),
      // transparent area the same size as the old column
      child: Stack(
        children: [
          if (showLastPrice)
            Positioned(
              right: 0,
              top: _chipTop(),
              width: PRICE_BAR_WIDTH,
              height: PRICE_INDICATOR_HEIGHT,
              child: Container(
                alignment: Alignment.center,
                color: lastCandle.isBull ? style.primaryBull : style.primaryBear,
                child: Text(
                  lastCandle.close.toStringAsFixed(5),
                  style: TextStyle(
                    color: style.secondaryTextColor,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

