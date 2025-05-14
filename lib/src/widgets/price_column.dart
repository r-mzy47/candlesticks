import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:flutter/material.dart';

/// Transparent hit‑box that sits *flush against the right edge* of the chart.
///
/// * forwards vertical‑drag so the user can manual‑scale  
/// * static price ladder is **gone**  
/// * coloured last‑price chip is optional via [showLastPrice]
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

    // kept only so DesktopChart / MobileChart calls still compile
    double? width, // ignored
  });

  /// Lowest visible price in the current viewport.
  final double low;

  /// Highest visible price in the current viewport.
  final double high;

  /// Height of the candle pane (without paddings).
  final double chartHeight;

  /// Latest candle – used to determine chip colour & value.
  final Candle lastCandle;

  /// Callback used for manual vertical scaling.
  final void Function(double) onScale;

  /// Current colour palette.
  final CandleSticksStyle style;

  /// Toggle the coloured last‑price chip.
  final bool showLastPrice;

  /// Pixel offset (from the top of the chart) for the chip.
  double _chipTop() => chartHeight +
      10 -
      (lastCandle.close - low) / (high - low) * chartHeight -
      MAIN_CHART_VERTICAL_PADDING;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Manual scale = vertical drag inside this 40 px strip.
      onVerticalDragUpdate: (details) => onScale(details.delta.dy),

      // Always stick the whole hit‑box to the RIGHT edge.
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: PRICE_BAR_WIDTH,          // ← identical width as before
          height: double.infinity,
          child: Stack(
            children: [
              if (showLastPrice)
                Positioned(
                  right : 0,               // always at the far‑right
                  top   : _chipTop(),
                  width : PRICE_BAR_WIDTH,
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
      ),
    );
  }
}
