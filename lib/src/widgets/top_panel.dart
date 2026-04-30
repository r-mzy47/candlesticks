import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:candlesticks/src/widgets/candle_info_text.dart';
import 'package:candlesticks/src/widgets/candle_sticks_style_provider.dart';
import 'package:flutter/material.dart';

class TopPanel extends StatefulWidget {
  const TopPanel({
    Key? key,
    required this.currentCandle,
  }) : super(key: key);

  final Candle? currentCandle;

  @override
  State<TopPanel> createState() => _TopPanelState();
}

class _TopPanelState extends State<TopPanel> {
  @override
  Widget build(BuildContext context) {
    CandleSticksStyle style = CandleSticksStyleProvider.of(context);

    return DefaultTextStyle(
      style: TextStyle(color: style.primaryTextColor),
      child: SizedBox(
        height: 20,
        child: widget.currentCandle != null
            ? CandleInfoText(
                candle: widget.currentCandle!,
                bullColor: style.primaryBull,
                bearColor: style.primaryBear,
                defaultStyle: TextStyle(color: style.borderColor, fontSize: 10),
              )
            : Container(),
      ),
    );
  }
}
