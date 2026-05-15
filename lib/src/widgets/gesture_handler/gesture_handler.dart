import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/models/price_scale.dart';
import 'package:candlesticks/src/widgets/gesture_handler/desktop_gesture_handler.dart';
import 'package:candlesticks/src/widgets/gesture_handler/mobile_gesture_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GestureHandler extends StatelessWidget {
  const GestureHandler({
    super.key,
    required this.maxHeight,
    required this.maxWidth,
    required this.candlesHighPrice,
    required this.candlesLowPrice,
    required this.controller,
    required this.viewPort,
    required this.onCrosshairXChange,
    required this.priceScale,
    required this.onPriceScaleToggle,
    required this.builder,
  });

  final double maxHeight;
  final double maxWidth;
  final double candlesHighPrice;
  final double candlesLowPrice;
  final CandlesticksController controller;
  final CandlesticksViewport viewPort;
  final void Function(double?) onCrosshairXChange;
  final PriceScale priceScale;
  final void Function() onPriceScaleToggle;

  final Widget Function(
    BuildContext context,
    double newHigh,
    double newLow,
    double? mouseHoverY,
    bool isPriceScaled,
  ) builder;

  bool get _isMobilePlatform {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobilePlatform) {
      return MobileGestureHandler(
        maxHeight: maxHeight,
        maxWidth: maxWidth,
        candlesHighPrice: candlesHighPrice,
        candlesLowPrice: candlesLowPrice,
        controller: controller,
        viewPort: viewPort,
        onCrosshairXChange: onCrosshairXChange,
        priceScale: priceScale,
        onPriceScaleToggle: onPriceScaleToggle,
        builder: builder,
      );
    }

    return DesktopGestureHandler(
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      candlesHighPrice: candlesHighPrice,
      candlesLowPrice: candlesLowPrice,
      controller: controller,
      viewPort: viewPort,
      onCrosshairXChange: onCrosshairXChange,
      priceScale: priceScale,
      onPriceScaleToggle: onPriceScaleToggle,
      builder: builder,
    );
  }
}
