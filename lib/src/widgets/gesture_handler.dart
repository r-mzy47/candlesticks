import 'dart:math';

import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/controller/candlesticks_controller.dart';
import 'package:candlesticks/src/controller/candlesticks_viewport.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class GestureHandler extends StatefulWidget {
  final double chartHeight;
  final CandleSticksStyle style;
  final int candlesCount;
  final double candlesHighPrice;
  final double candlesLowPrice;
  final CandlesticksController controller;
  final CandlesticksViewport viewPort;

  final Widget Function(
    BuildContext context,
    double newHigh,
    double newLow,
    double? mouseHoverX,
    double? mouseHoverY,
    bool showHoverIndicator,
    bool isPriceScaled,
    void Function(double, double, double) onPriceBarScale,
  ) builder;

  const GestureHandler({
    super.key,
    required this.style,
    required this.chartHeight,
    required this.candlesCount,
    required this.builder,
    required this.candlesHighPrice,
    required this.candlesLowPrice,
    required this.controller,
    required this.viewPort,
  });

  @override
  State<GestureHandler> createState() => _GestureHandlerState();
}

class _GestureHandlerState extends State<GestureHandler> {
  double? mouseHoverX;
  double? mouseHoverY;
  bool isDragging = false;
  bool showHoverIndicator = true;
  double? manualScaleHigh;
  double? manualScaleLow;
  int lastIndex = -10;
  double lastX = 0;

  void _onMouseExit(PointerEvent details) {
    setState(() {
      mouseHoverX = null;
      mouseHoverY = null;
    });
  }

  void _onMouseHover(PointerEvent details) {
    setState(() {
      mouseHoverX = details.localPosition.dx;
      mouseHoverY = details.localPosition.dy;
    });
  }

  void onScaleUpdate(double scale) {
    double newCandleWidth = widget.viewPort.candleWidth + scale / 50;
    newCandleWidth = min(newCandleWidth, 20);
    newCandleWidth = max(newCandleWidth, 2);
    widget.controller.setZoom(newCandleWidth);
  }

  void onPanEnd() {
    lastIndex = widget.viewPort.scrollIndex;
  }

  void onHorizontalDragUpdate(double x) {
    x = x - lastX;
    int NewIndex = lastIndex + x ~/ widget.viewPort.candleWidth;
    NewIndex = max(NewIndex, -10);
    NewIndex = min(NewIndex, widget.candlesCount - 1);

    widget.controller.jumpTo(NewIndex);
  }

  void onPanDown(double value) {
    lastX = value;
    lastIndex = widget.viewPort.scrollIndex;
  }

  void onPriceBarScale(delta, candlesHighPrice, candlesLowPrice) {
    if (manualScaleHigh == null) {
      manualScaleHigh = candlesHighPrice;
      manualScaleLow = candlesLowPrice;
    }
    setState(() {
      double deltaPrice =
          delta / widget.chartHeight * (manualScaleHigh! - manualScaleLow!);
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
          mouseHoverX,
          mouseHoverY,
          showHoverIndicator,
          manualScaleHigh != null,
          onPriceBarScale,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 50, bottom: 20),
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                if (pointerSignal.scrollDelta.dy.abs() >
                    pointerSignal.scrollDelta.dx.abs())
                  onScaleUpdate(pointerSignal.scrollDelta.dy * -1);
                else {
                  int NewIndex = widget.viewPort.scrollIndex +
                      -1 *
                          pointerSignal.scrollDelta.dx ~/
                          widget.viewPort.candleWidth;
                  NewIndex = max(NewIndex, -10);
                  NewIndex = min(NewIndex, widget.candlesCount - 1);
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
                  mouseHoverX = update.localPosition.dx;
                  mouseHoverY = update.localPosition.dy;
                  onHorizontalDragUpdate(update.localPosition.dx);
                  setState(() {
                    if (manualScaleHigh != null) {
                      double deltaPrice = update.delta.dy /
                          widget.chartHeight *
                          (manualScaleHigh! - manualScaleLow!);
                      manualScaleHigh = manualScaleHigh! + deltaPrice;
                      manualScaleLow = manualScaleLow! + deltaPrice;
                    }
                  });
                },
                onPanEnd: (update) {
                  onPanEnd();
                  setState(() {
                    isDragging = false;
                  });
                  Future.delayed(Duration(milliseconds: 300), () {
                    setState(() {
                      showHoverIndicator = true;
                    });
                  });
                },
                onPanDown: (update) {
                  onPanDown(update.localPosition.dx);
                  setState(() {
                    isDragging = true;
                    showHoverIndicator = false;
                  });
                },
              ),
            ),
          ),
        ),
        Positioned(
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
            onPressed: manualScaleHigh == null
                ? null
                : () {
                    setState(
                      () {
                        manualScaleHigh = null;
                        manualScaleLow = null;
                      },
                    );
                  },
          ),
        )
      ],
    );
  }
}
