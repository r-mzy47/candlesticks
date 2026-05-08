import 'package:flutter/material.dart';

class HighLowAnimator extends StatelessWidget {
  final double candlesHighPrice;
  final double candlesLowPrice;
  final bool diableAnimation;

  final Widget Function(BuildContext context, double high, double low) builder;

  const HighLowAnimator({
    super.key,
    required this.candlesHighPrice,
    required this.candlesLowPrice,
    required this.diableAnimation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween(end: candlesHighPrice),
      duration: Duration(milliseconds: diableAnimation ? 0 : 300),
      builder: (context, double high, _) {
        return TweenAnimationBuilder(
          tween: Tween(end: candlesLowPrice),
          duration: Duration(milliseconds: diableAnimation ? 0 : 300),
          builder: (context, double low, _) {
            return builder(context, high, low);
          },
        );
      },
    );
  }
}
