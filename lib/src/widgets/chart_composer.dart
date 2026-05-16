import 'dart:math';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport_tween.dart';
import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/widgets/axis/time_axis.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/main_chart_pane.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:flutter/material.dart';
import '../models/candle.dart';

/// This widget manages gestures
/// Calculates the highest and lowest price of visible candles.
/// Updates right-hand side numbers.
/// And pass values down to [CandleStickWidget].
class ChartComposer extends StatefulWidget {
  /// list of all candles to display in chart
  final List<Candle> candles;

  final CandlesticksController controller;

  const ChartComposer({
    super.key,
    required this.candles,
    required this.controller,
  });

  @override
  State<ChartComposer> createState() => _ChartComposerState();
}

class _ChartComposerState extends State<ChartComposer> {
  double? crosshairX;

  void onCrosshairXChange(double? value) {
    setState(() {
      crosshairX = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // determine chart width
        final double maxWidth = constraints.maxWidth;
        final double chartsWidth = maxWidth - PRICE_BAR_WIDTH;

        final metricsChanged = widget.controller.updateChartMetrics(
          candlesCount: widget.candles.length,
          chartWidth: chartsWidth,
        );

        if (metricsChanged) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;

            widget.controller.syncViewportWithMetrics();
          });
        }

        return ValueListenableBuilder(
          valueListenable: widget.controller,
          builder: (context, viewPort, child) {
            return TweenAnimationBuilder<CandlesticksViewport>(
              tween: CandlesticksViewportTween(
                end: viewPort,
              ),
              duration: Duration(
                milliseconds: max(
                  120,
                  viewPort.scrollIndexAnimationDurationMs,
                ),
              ),
              curve: Curves.linear,
              builder: (context, animatedViewport, _) {
                final double? crosshairXFromRight =
                    crosshairX == null ? null : chartsWidth - crosshairX!;

                return Container(
                  color: CandleSticksStyleProvider.of(context)
                      .chartBackgroundColor,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          right: PRICE_BAR_WIDTH,
                        ), // padding rigth PRICE_BAR_WIDTH
                        child: TimeAxis(
                          crosshairXFromRight: crosshairXFromRight,
                          candles: widget.candles,
                          viewport: animatedViewport,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: DATE_BAR_HEIGHT,
                        ), // padding rigth PRICE_BAR_WIDTH
                        child: Column(
                          children: [
                            Expanded(
                              child: MainChartPane(
                                candles: widget.candles,
                                controller: widget.controller,
                                viewPort: animatedViewport,
                                onCrosshairXChange: onCrosshairXChange,
                                crosshairXFromRight: crosshairXFromRight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
