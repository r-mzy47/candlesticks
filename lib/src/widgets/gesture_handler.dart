import 'dart:math';

import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class GestureHandler extends StatefulWidget {
  final double maxHeight;
  final double maxWidth;
  final CandleSticksStyle style;
  final int candlesCount;
  final double candlesHighPrice;
  final double candlesLowPrice;
  final CandlesticksController controller;
  final CandlesticksViewport viewPort;
  final void Function(int?) onHoveredCandleIndexChange;

  final Widget Function(
    BuildContext context,
    double newHigh,
    double newLow,
    double? mouseHoverY,
    bool isPriceScaled,
  ) builder;

  const GestureHandler({
    super.key,
    required this.style,
    required this.maxHeight,
    required this.maxWidth,
    required this.candlesCount,
    required this.builder,
    required this.candlesHighPrice,
    required this.candlesLowPrice,
    required this.controller,
    required this.viewPort,
    required this.onHoveredCandleIndexChange,
  });

  @override
  State<GestureHandler> createState() => _GestureHandlerState();
}

class _GestureHandlerState extends State<GestureHandler> {
  double? mouseHoverY;
  bool isDragging = false;
  double? manualScaleHigh;
  double? manualScaleLow;

  int scrollIndexWhenUserStartsDragging = -10;
  double mouseXpositionWhenUserStartsDragging = 0;

  void _onMouseExit(PointerEvent details) {
    widget.onHoveredCandleIndexChange(null);
    setState(() {
      mouseHoverY = null;
    });
  }

  void _onMouseHover(PointerEvent details) {
    int hoveredIndex =
        ((widget.maxWidth - PRICE_BAR_WIDTH) - details.localPosition.dx) ~/
                widget.viewPort.candleWidth +
            widget.viewPort.scrollIndex;
    hoveredIndex = hoveredIndex.clamp(0, widget.candlesCount - 1);
    widget.onHoveredCandleIndexChange(hoveredIndex);
    setState(() {
      mouseHoverY = details.localPosition.dy;
    });
  }

  void onScaleUpdate(double scale) {
    double newCandleWidth = widget.viewPort.candleWidth + scale / 50;
    widget.controller.setZoom(newCandleWidth);
  }

  void onHorizontalDragUpdate(double x) {
    x = x - mouseXpositionWhenUserStartsDragging;
    int NewIndex =
        scrollIndexWhenUserStartsDragging + x ~/ widget.viewPort.candleWidth;
    NewIndex = max(NewIndex, -10);
    NewIndex = min(NewIndex, widget.candlesCount - 1);

    widget.controller.jumpTo(NewIndex);
  }

  void onPanDown(double value) {
    mouseXpositionWhenUserStartsDragging = value;
    scrollIndexWhenUserStartsDragging = widget.viewPort.scrollIndex;
  }

  void onPriceBarScale(delta) {
    if (manualScaleHigh == null) {
      manualScaleHigh = widget.candlesHighPrice;
      manualScaleLow = widget.candlesLowPrice;
    }
    setState(() {
      double deltaPrice =
          delta / widget.maxHeight * (manualScaleHigh! - manualScaleLow!);
      manualScaleHigh = manualScaleHigh! + deltaPrice;
      manualScaleLow = manualScaleLow! - deltaPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              _onMouseHover(pointerSignal);
              if (pointerSignal is PointerScrollEvent) {
                if (pointerSignal.scrollDelta.dy.abs() >
                    pointerSignal.scrollDelta.dx.abs())
                  onScaleUpdate(pointerSignal.scrollDelta.dy * -1);
                else {
                  int NewIndex = widget.viewPort.scrollIndex +
                      -1 *
                          pointerSignal.scrollDelta.dx ~/
                          widget.viewPort.candleWidth;
                  NewIndex = NewIndex.clamp(-10, widget.candlesCount - 1);
                  widget.controller.jumpTo(NewIndex);
                }
              }
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
                  mouseHoverY = update.localPosition.dy;
                  onHorizontalDragUpdate(update.localPosition.dx);
                  setState(() {
                    if (manualScaleHigh != null) {
                      double deltaPrice = update.delta.dy /
                          widget.maxHeight *
                          (manualScaleHigh! - manualScaleLow!);
                      manualScaleHigh = manualScaleHigh! + deltaPrice;
                      manualScaleLow = manualScaleLow! + deltaPrice;
                    }
                  });
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
        manualScaleHigh != null
            ? Positioned(
                right: 0,
                bottom: 0,
                width: PRICE_BAR_WIDTH,
                height: 20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: widget.style.hoverIndicatorBackgroundColor,
                    foregroundColor: widget.style.secondaryTextColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    "Auto",
                    style: TextStyle(
                      color: widget.style.secondaryTextColor,
                      fontSize: 12,
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
                ),
              )
            : Container(),
      ],
    );
  }
}
