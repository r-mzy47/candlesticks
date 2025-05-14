import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:flutter/material.dart';

/// Transparent hit‑box on the right edge of the main chart.
/// • forwards vertical‑drag so the user can manual‑scale
/// • static price ladder is *removed*
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

    // kept only so existing calls (DesktopChart / MobileChart) still match
    double? width, // ignored
  });

  /// lowest visible price
  final double low;

  /// highest visible price
  final double high;

  /// height of the candle pane (excluding paddings)
  final double chartHeight;

  /// most‑recent candle (to colour the chip)
  final Candle lastCandle;

  /// callback used for manual vertical scaling
  final void Function(double) onScale;

  /// current colour palette
  final CandleSticksStyle style;

  /// toggles the coloured last‑price chip
  final bool showLastPrice;

  // pixel y‑offset for the price chip
  double _chipTop() => chartHeight +
      10 -
      (lastCandle.close - low) / (high - low) * chartHeight -
      MAIN_CHART_VERTICAL_PADDING;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (d) => onScale(d.delta.dy),
      child: SizedBox(
        width: PRICE_BAR_WIDTH, // keeps hit‑box the same size as before
        height: double.infinity,
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
                  color: lastCandle.isBull
                      ? style.primaryBull
                      : style.primaryBear,
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
      ),
    );
  }
}
