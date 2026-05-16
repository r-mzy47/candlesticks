import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';

class CandleSticksStyleProvider extends InheritedWidget {
  final CandleSticksStyle style;

  const CandleSticksStyleProvider({
    super.key,
    required this.style,
    required super.child,
  });

  static CandleSticksStyle of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CandleSticksStyleProvider>()!
        .style;
  }

  @override
  bool updateShouldNotify(CandleSticksStyleProvider oldWidget) {
    return style != oldWidget.style;
  }
}
