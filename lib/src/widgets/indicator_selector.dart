import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/models/indicator.dart';
import 'package:candlesticks/src/widgets/candle_info_text.dart';
import 'package:flutter/material.dart';

class IndicatorSelector extends StatefulWidget {
  const IndicatorSelector({
    Key? key,
    required this.currentCandle,
    required this.indicators,
    required this.toggleIndicatorVisibility,
    required this.unvisibleIndicators,
    required this.onRemoveIndicator,
    required this.style,
  }) : super(key: key);

  final Candle? currentCandle;
  final List<Indicator> indicators;
  final void Function(String indicatorName) toggleIndicatorVisibility;
  final List<String> unvisibleIndicators;
  final void Function(String indicatorName)? onRemoveIndicator;
  final CandleSticksStyle style;

  @override
  State<IndicatorSelector> createState() => _IndicatorSelectorState();
}

class _IndicatorSelectorState extends State<IndicatorSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: widget.indicators.map((indicator) {
              final bool isVisible = !widget.unvisibleIndicators.contains(indicator.name);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    widget.toggleIndicatorVisibility(indicator.name);
                  },
                  child: Text(
                    indicator.name,
                    style: TextStyle(
                      color: widget.style.primaryTextColor,
                      fontWeight: isVisible ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
