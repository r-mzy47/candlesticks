import 'package:flutter/services.dart';
import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/models/price_scale.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class DesktopGestureHandler extends StatefulWidget {
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

  const DesktopGestureHandler({
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
  State<DesktopGestureHandler> createState() => _DesktopGestureHandlerState();
}

class _DesktopGestureHandlerState extends State<DesktopGestureHandler> {
  double? crosshairY;
  bool isDragging = false;
  double? manualScaleHigh;
  double? manualScaleLow;

  double scrollIndexWhenUserStartsDragging = -10;
  double mouseXpositionWhenUserStartsDragging = 0;

  void _onMouseExit(PointerEvent details) {
    widget.onCrosshairXChange(null);
    setState(() {
      crosshairY = null;
    });
  }

  void _onMouseHover(PointerEvent details) {
    widget.onCrosshairXChange(details.localPosition.dx);
    setState(() {
      crosshairY = details.localPosition.dy;
    });
  }

  void onScaleUpdate(double scale) {
    widget.controller.zoomBy((1 + scale / 200));
  }

  void onAnchoredZoomScroll(PointerScrollEvent details) {
    final scrollDelta = details.scrollDelta.dy * -1;

    final chartWidth = widget.maxWidth - PRICE_BAR_WIDTH;
    if (chartWidth <= 0) return;

    final pointerX = details.localPosition.dx;

    if (pointerX < 0 || pointerX > chartWidth) return;

    final mouseXFromRight = chartWidth - pointerX;

    final zoomFactor = (1 + scrollDelta / 200);

    widget.controller.zoomAround(
      zoomFactor: zoomFactor,
      anchorDistanceFromRight: mouseXFromRight,
    );
  }

  void onHorizontalDragUpdate(DragUpdateDetails update) {
    double x = update.localPosition.dx;
    x = x - mouseXpositionWhenUserStartsDragging;
    double newIndex =
        scrollIndexWhenUserStartsDragging + x / widget.viewPort.candleWidth;

    widget.controller.jumpTo(newIndex);
    widget.onCrosshairXChange(update.localPosition.dx);
  }

  void onPanDown(double value) {
    mouseXpositionWhenUserStartsDragging = value;
    scrollIndexWhenUserStartsDragging = widget.viewPort.scrollIndex;
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

  void onVerticalDragUpdate(DragUpdateDetails update) {
    double deltaY = update.delta.dy;
    setState(() {
      crosshairY = update.localPosition.dy;

      if (manualScaleHigh == null || manualScaleLow == null) return;

      if (!widget.priceScale.isValid(manualScaleHigh!) ||
          !widget.priceScale.isValid(manualScaleLow!) ||
          manualScaleHigh! <= manualScaleLow!) {
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    CandleSticksStyle style = CandleSticksStyleProvider.of(context);
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
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                final isAnchoredZoomModifierPressed =
                    HardwareKeyboard.instance.isMetaPressed || // macOS Command
                        HardwareKeyboard
                            .instance.isControlPressed || // Windows/Linux Ctrl
                        HardwareKeyboard.instance.isAltPressed; // web

                if (isAnchoredZoomModifierPressed) {
                  onAnchoredZoomScroll(pointerSignal);
                  return;
                }

                if (pointerSignal.scrollDelta.dy.abs() >
                    pointerSignal.scrollDelta.dx.abs()) {
                  onScaleUpdate(pointerSignal.scrollDelta.dy * -1);
                } else {
                  widget.controller.scrollByPixels(
                    deltaX: pointerSignal.scrollDelta.dx,
                  );
                }
              }
              _onMouseHover(pointerSignal);
            },
            child: MouseRegion(
              cursor: isDragging
                  ? SystemMouseCursors.grabbing
                  : SystemMouseCursors.precise,
              onHover: _onMouseHover,
              onExit: _onMouseExit,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (update) {
                  onHorizontalDragUpdate(update);
                  onVerticalDragUpdate(update);
                },
                onPanEnd: (update) {
                  setState(() {
                    isDragging = false;
                  });
                },
                onPanDown: (update) {
                  onPanDown(update.localPosition.dx);
                  setState(() {
                    isDragging = true;
                  });
                },
              ),
            ),
          ),
        ),

        // Price bar drag area.
        Positioned(
          height: widget.maxHeight,
          bottom: 0,
          right: 0,
          width: PRICE_BAR_WIDTH,
          child: GestureDetector(
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
            color: style.chartBackgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: manualScaleHigh == null
                          ? style.scaleButtonActiveBackgroundColor
                          : style.scaleButtonInactiveBackgroundColor,
                      foregroundColor: manualScaleHigh == null
                          ? style.scaleButtonActiveTextColor
                          : style.scaleButtonInactiveTextColor,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    onPressed: () {
                      setState(
                        () {
                          manualScaleHigh = null;
                          manualScaleLow = null;
                        },
                      );
                    },
                    child: const Text('A'),
                  ),
                ),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.priceScale == log10PriceScale
                          ? style.scaleButtonActiveBackgroundColor
                          : style.scaleButtonInactiveBackgroundColor,
                      foregroundColor: widget.priceScale == log10PriceScale
                          ? style.scaleButtonActiveTextColor
                          : style.scaleButtonInactiveTextColor,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    onPressed: () {
                      widget.onPriceScaleToggle();
                      setState(
                        () {
                          manualScaleHigh = null;
                          manualScaleLow = null;
                        },
                      );
                    },
                    child: const Text('L'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.viewPort.scrollIndex > 10)
          Positioned(
            bottom: 150,
            right: 150,
            child: IconButton(
              onPressed: () {
                widget.controller.animateTo(-10);
              },
              icon: Icon(Icons.keyboard_double_arrow_right),
            ),
          ),
      ],
    );
  }
}
