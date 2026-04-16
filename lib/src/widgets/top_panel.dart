import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/widgets/candle_info_text.dart';
import 'package:flutter/material.dart';

class TopPanel extends StatefulWidget {
  const TopPanel({
    Key? key,
    required this.currentCandle,
    required this.style,
  }) : super(key: key);

  final Candle? currentCandle;
  final CandleSticksStyle style;

  @override
  State<TopPanel> createState() => _TopPanelState();
}

class _TopPanelState extends State<TopPanel> {
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(color: widget.style.primaryTextColor),
      child: SizedBox(
        height: 20,
        child: widget.currentCandle != null
            ? CandleInfoText(
                candle: widget.currentCandle!,
                bullColor: widget.style.primaryBull,
                bearColor: widget.style.primaryBear,
                defaultStyle:
                    TextStyle(color: widget.style.borderColor, fontSize: 10),
              )
            : Container(),
      ),
    );
  }
}
