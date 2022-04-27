import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/models/indicator.dart';
import 'package:candlesticks/src/widgets/candle_info_text.dart';
import 'package:flutter/material.dart';

class TopPanel extends StatefulWidget {
  const TopPanel({
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
  State<TopPanel> createState() => _TopPanelState();
}

class _TopPanelState extends State<TopPanel> {
  bool showIndicatorNames = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(color: widget.style.primaryTextColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 20,
            child: widget.currentCandle != null
                ? CandleInfoText(
                    candle: widget.currentCandle!,
                    bullColor: widget.style.primaryBull,
                    bearColor: widget.style.primaryBear,
                    defaultStyle: TextStyle(
                        color: widget.style.borderColor, fontSize: 10),
                  )
                : Container(),
          ),
          showIndicatorNames || widget.indicators.length == 1
              ? Column(
                  children: widget.indicators
                      .map(
                        (e) => _PanelButton(
                          child: Row(
                            children: [
                              Text(e.name),
                              SizedBox(
                                width: 10,
                              ),
                              GestureDetector(
                                onTap: () {
                                  widget.toggleIndicatorVisibility(e.name);
                                },
                                child: widget.unvisibleIndicators
                                        .contains(e.name)
                                    ? Icon(
                                        Icons.visibility_off_outlined,
                                        size: 16,
                                        color: widget.style.primaryTextColor,
                                      )
                                    : Icon(Icons.visibility_outlined,
                                        size: 16,
                                        color: widget.style.primaryTextColor),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              widget.onRemoveIndicator != null
                                  ? GestureDetector(
                                      onTap: () {
                                        widget.onRemoveIndicator!(e.name);
                                      },
                                      child: Icon(Icons.close,
                                          size: 16,
                                          color: widget.style.primaryTextColor),
                                    )
                                  : Container(),
                            ],
                          ),
                          borderColor: widget.style.borderColor,
                        ),
                      )
                      .toList(),
                )
              : Container(),
          widget.indicators.length > 1
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      showIndicatorNames = !showIndicatorNames;
                    });
                  },
                  child: _PanelButton(
                    borderColor: widget.style.borderColor,
                    child: Row(
                      children: [
                        Icon(
                            showIndicatorNames
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: widget.style.primaryTextColor),
                        Text(widget.indicators.length.toString()),
                      ],
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    Key? key,
    required this.child,
    required this.borderColor,
  }) : super(key: key);

  final Widget child;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Container(
            height: 25,
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(5),
              ),
            ),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}
