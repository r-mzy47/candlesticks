import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/indicator.dart';
import 'package:candlesticks/src/theme/theme_data.dart';
import 'package:candlesticks/src/widgets/candle_info_text.dart';
import 'package:flutter/material.dart';

class TopPanel extends StatefulWidget {
  const TopPanel({
    Key? key,
    required this.currentCandle,
    required this.indicators,
    required this.toggleIndicatorVisibility,
    required this.unvisibleIndicators,
  }) : super(key: key);
  final Candle? currentCandle;
  final List<Indicator> indicators;
  final void Function(String indicatorName) toggleIndicatorVisibility;
  final List<String> unvisibleIndicators;
  @override
  State<TopPanel> createState() => _TopPanelState();
}

class _TopPanelState extends State<TopPanel> {
  bool showIndicatorNames = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
          child: widget.currentCandle != null
              ? CandleInfoText(candle: widget.currentCandle!)
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
                              child: widget.unvisibleIndicators.contains(e.name)
                                  ? Icon(Icons.visibility_outlined)
                                  : Icon(Icons.visibility_off_outlined),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            GestureDetector(
                              onTap: e.onRemove,
                              child: Icon(Icons.close),
                            ),
                          ],
                        ),
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
                  child: Row(
                    children: [
                      Icon(showIndicatorNames
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded),
                      Text(widget.indicators.length.toString()),
                    ],
                  ),
                ),
              )
            : Container(),
      ],
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;

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
                color: Theme.of(context).grayColor,
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
