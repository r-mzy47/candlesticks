import 'dart:math' as math;

import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Candlesticks renders correctly', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final candles = List.generate(80, (index) {
      final open = 100 + index * 0.5;
      final close = index.isEven ? open + 3 : open - 2;
      final high = math.max(open, close) + 2;
      final low = math.min(open, close) - 2;

      return Candle(
        date: DateTime(2024, 1, 1).add(Duration(hours: index)),
        high: high,
        low: low,
        open: open,
        close: close,
        volume: 1000 + index * 10,
      );
    });

    const chartKey = Key('candlesticks-chart');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          fontFamily: 'Roboto',
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 800,
              height: 600,
              child: RepaintBoundary(
                key: chartKey,
                child: Candlesticks(
                  candles: candles,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(chartKey),
      matchesGoldenFile('goldens/candlesticks_basic.png'),
    );
  });
}
