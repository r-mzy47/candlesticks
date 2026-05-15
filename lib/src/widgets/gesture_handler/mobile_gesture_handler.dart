import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/models/price_scale.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:flutter/material.dart';

class MobileGestureHandler extends StatefulWidget {
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
    double? crosshairY,
    bool isPriceScaled,
  ) builder;

  const MobileGestureHandler({
    super.key,
    required this.maxHeight,
    required this.maxWidth,
    required this.builder,
    required this.candlesHighPrice,
    required this.candlesLowPrice,
    required this.controller,
    required this.viewPort,
    required this.onCrosshairXChange,
    required this.priceScale,
    required this.onPriceScaleToggle,
  });

  @override
  State<MobileGestureHandler> createState() => _MobileGestureHandlerState();
}

class _MobileGestureHandlerState extends State<MobileGestureHandler> {
  double? crosshairY;

  double? manualScaleHigh;
  double? manualScaleLow;

  bool isTouchHoverActive = false;

  double scrollIndexWhenScaleStarted = -10;
  double focalPointXWhenScaleStarted = 0;
  double lastPinchScale = 1;

  double get chartWidth => widget.maxWidth - PRICE_BAR_WIDTH;

  void onScaleStart(ScaleStartDetails details) {
    scrollIndexWhenScaleStarted = widget.viewPort.scrollIndex;
    focalPointXWhenScaleStarted = details.localFocalPoint.dx;
    lastPinchScale = 1;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (isTouchHoverActive) return;

    if (details.pointerCount >= 2) {
      onPinchZoom(details);
      return;
    }

    onHorizontalDragUpdate(details);
    onManualPriceScalePan(details.focalPointDelta.dy);
  }

  void onScaleEnd(ScaleEndDetails details) {
    lastPinchScale = 1;
  }

  void onPinchZoom(ScaleUpdateDetails details) {
    if (chartWidth <= 0) return;

    final pointerX = details.localFocalPoint.dx;

    if (pointerX < 0 || pointerX > chartWidth) return;

    final anchorDistanceFromRight = chartWidth - pointerX;

    final zoomFactor = details.scale / lastPinchScale;
    lastPinchScale = details.scale;

    if (zoomFactor <= 0) return;

    widget.controller.zoomAround(
      zoomFactor: zoomFactor,
      anchorDistanceFromRight: anchorDistanceFromRight,
    );
  }

  void onHorizontalDragUpdate(ScaleUpdateDetails details) {
    final deltaX = details.localFocalPoint.dx - focalPointXWhenScaleStarted;

    double newIndex =
        scrollIndexWhenScaleStarted + deltaX / widget.viewPort.candleWidth;

    widget.controller.jumpTo(newIndex);
  }

  void onManualPriceScalePan(double deltaY) {
    if (manualScaleHigh == null || manualScaleLow == null) return;

    if (!widget.priceScale.isValid(manualScaleHigh!) ||
        !widget.priceScale.isValid(manualScaleLow!) ||
        manualScaleHigh! <= manualScaleLow!) {
      return;
    }

    setState(() {
      final transformedHigh = widget.priceScale.transform(manualScaleHigh!);
      final transformedLow = widget.priceScale.transform(manualScaleLow!);

      final transformedDelta =
          deltaY / widget.maxHeight * (transformedHigh - transformedLow);

      manualScaleHigh = widget.priceScale.inverse(
        transformedHigh + transformedDelta,
      );

      manualScaleLow = widget.priceScale.inverse(
        transformedLow + transformedDelta,
      );
    });
  }

  void onPriceBarScale(double delta) {
    if (manualScaleHigh == null) {
      manualScaleHigh = widget.candlesHighPrice;
      manualScaleLow = widget.candlesLowPrice;
    }

    if (!widget.priceScale.isValid(manualScaleHigh!) ||
        !widget.priceScale.isValid(manualScaleLow!) ||
        manualScaleHigh! <= manualScaleLow!) {
      return;
    }

    setState(() {
      final transformedHigh = widget.priceScale.transform(manualScaleHigh!);
      final transformedLow = widget.priceScale.transform(manualScaleLow!);

      final transformedDelta =
          delta / widget.maxHeight * (transformedHigh - transformedLow);

      manualScaleHigh = widget.priceScale.inverse(
        transformedHigh + transformedDelta,
      );

      manualScaleLow = widget.priceScale.inverse(
        transformedLow - transformedDelta,
      );
    });
  }

  void showTouchHover(Offset localPosition) {
    widget.onCrosshairXChange(localPosition.dx);

    setState(() {
      isTouchHoverActive = true;
      crosshairY = localPosition.dy;
    });
  }

  void hideTouchHover() {
    widget.onCrosshairXChange(null);

    setState(() {
      isTouchHoverActive = false;
      crosshairY = null;
    });
  }

  void onLongPressStart(LongPressStartDetails details) {
    showTouchHover(details.localPosition);
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    showTouchHover(details.localPosition);
  }

  void onLongPressEnd(LongPressEndDetails details) {
    hideTouchHover();
  }

  void onLongPressCancel() {
    hideTouchHover();
  }

  void resetManualScale() {
    setState(() {
      manualScaleHigh = null;
      manualScaleLow = null;
    });
  }

  void togglePriceScale() {
    widget.onPriceScaleToggle();
    resetManualScale();
  }

  @override
  Widget build(BuildContext context) {
    final CandleSticksStyle style = CandleSticksStyleProvider.of(context);

    return Stack(
      children: [
        widget.builder(
          context,
          manualScaleHigh ?? widget.candlesHighPrice,
          manualScaleLow ?? widget.candlesLowPrice,
          crosshairY,
          manualScaleHigh != null,
        ),

        // Main chart touch area.
        Positioned.fill(
          right: PRICE_BAR_WIDTH,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: onScaleStart,
            onScaleUpdate: onScaleUpdate,
            onScaleEnd: onScaleEnd,
            onLongPressStart: onLongPressStart,
            onLongPressMoveUpdate: onLongPressMoveUpdate,
            onLongPressEnd: onLongPressEnd,
            onLongPressCancel: onLongPressCancel,
          ),
        ),

        // Price bar drag area.
        Positioned(
          height: widget.maxHeight,
          bottom: 0,
          right: 0,
          width: PRICE_BAR_WIDTH,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (details) {
              onPriceBarScale(details.delta.dy);
            },
          ),
        ),

        // Auto-scale and log-scale buttons.
        Positioned(
          right: 0,
          bottom: 0,
          width: PRICE_BAR_WIDTH,
          height: 22,
          child: Container(
            color: style.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: manualScaleHigh == null
                          ? style.hoverIndicatorBackgroundColor
                          : style.secondaryTextColor,
                      foregroundColor: manualScaleHigh == null
                          ? style.secondaryTextColor
                          : style.hoverIndicatorBackgroundColor,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    onPressed: resetManualScale,
                    child: const Text('A'),
                  ),
                ),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.priceScale == log10PriceScale
                          ? style.hoverIndicatorBackgroundColor
                          : style.secondaryTextColor,
                      foregroundColor: widget.priceScale == log10PriceScale
                          ? style.secondaryTextColor
                          : style.hoverIndicatorBackgroundColor,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    onPressed: togglePriceScale,
                    child: const Text('L'),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (widget.viewPort.scrollIndex > 10)
          Positioned(
            bottom: 100,
            right: 100,
            child: IconButton(
              onPressed: () {
                widget.controller.animateTo(-10);
              },
              icon: const Icon(Icons.keyboard_double_arrow_right),
            ),
          ),
      ],
    );
  }
}
