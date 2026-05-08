import 'package:flutter/services.dart';
import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/models/price_scale.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class GestureHandler extends StatefulWidget {
  final double maxHeight;
  final double maxWidth;
  final int candlesCount;
  final double candlesHighPrice;
  final double candlesLowPrice;
  final CandlesticksController controller;
  final CandlesticksViewport viewPort;
  final void Function(double?) onMouseHoverXChange;
  final PriceScale priceScale;
  final void Function() onPriceScaleToggle;

  final Widget Function(
    BuildContext context,
    double newHigh,
    double newLow,
    double? mouseHoverY,
    bool isPriceScaled,
  ) builder;

  const GestureHandler({
    super.key,
    required this.maxHeight,
    required this.maxWidth,
    required this.candlesCount,
    required this.builder,
    required this.candlesHighPrice,
    required this.candlesLowPrice,
    required this.controller,
    required this.viewPort,
    required this.onMouseHoverXChange,
    required this.priceScale,
    required this.onPriceScaleToggle,
  });

  @override
  State<GestureHandler> createState() => _GestureHandlerState();
}

class _GestureHandlerState extends State<GestureHandler> {
  double? mouseHoverY;
  bool isDragging = false;
  double? manualScaleHigh;
  double? manualScaleLow;

  double scrollIndexWhenUserStartsDragging = -10;
  double mouseXpositionWhenUserStartsDragging = 0;

  void _onMouseExit(PointerEvent details) {
    widget.onMouseHoverXChange(null);
    setState(() {
      mouseHoverY = null;
    });
  }

  void _onMouseHover(PointerEvent details) {
    widget.onMouseHoverXChange(details.localPosition.dx);
    setState(() {
      mouseHoverY = details.localPosition.dy;
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
      candlesCount: widget.candlesCount,
    );
  }

  void onHorizontalDragUpdate(DragUpdateDetails update) {
    double x = update.localPosition.dx;
    x = x - mouseXpositionWhenUserStartsDragging;
    double newIndex =
        scrollIndexWhenUserStartsDragging + x / widget.viewPort.candleWidth;

    newIndex = min(newIndex, widget.candlesCount - 1);

    widget.controller.jumpTo(newIndex);
    widget.onMouseHoverXChange(update.localPosition.dx);
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
      mouseHoverY = update.localPosition.dy;

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
          mouseHoverY,
          manualScaleHigh != null,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 50),
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                final isAnchoredZoomModifierPressed =
                    HardwareKeyboard.instance.isMetaPressed || // macOS Command
                        HardwareKeyboard
                            .instance.isControlPressed; // Windows/Linux Ctrl

                if (isAnchoredZoomModifierPressed) {
                  onAnchoredZoomScroll(pointerSignal);
                  return;
                }

                if (pointerSignal.scrollDelta.dy.abs() >
                    pointerSignal.scrollDelta.dx.abs())
                  onScaleUpdate(pointerSignal.scrollDelta.dy * -1);
                else {
                  widget.controller.scrollByPixels(
                    deltaX: pointerSignal.scrollDelta.dx,
                    candlesCount: widget.candlesCount,
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
                Container(
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
                Container(
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
                )
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
