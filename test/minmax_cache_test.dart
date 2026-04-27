import 'package:flutter_test/flutter_test.dart';

// Change these imports based on your project path.
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/data/minmax_cache.dart';

void main() {
  Candle candle(
    int minute, {
    required double high,
    required double low,
  }) {
    return Candle(
      date: DateTime(2024, 1, 1, 0, minute),
      high: high,
      low: low,
      open: 0,
      close: 0,
      volume: 0,
    );
  }

  group('CandleMinMaxCache', () {
    test('builds initial ranges and queries full range', () {
      final cache = MinMaxCache(rangeSize: 3);

      final candles = [
        candle(5, high: 10, low: 5),
        candle(4, high: 12, low: 4),
        candle(3, high: 8, low: 6),
        candle(2, high: 20, low: 2),
        candle(1, high: 15, low: 7),
        candle(0, high: 9, low: 1),
      ];

      cache.updateCandles(candles);

      final result = cache.queryByIndex(0, 5);

      expect(result.maxHigh, 20);
      expect(result.minLow, 1);
      expect(result.startTime, candles[5].date);
      expect(result.endTime, candles[0].date);
    });

    test('queries partial range correctly', () {
      final cache = MinMaxCache(rangeSize: 3);

      final candles = [
        candle(5, high: 10, low: 5),
        candle(4, high: 12, low: 4),
        candle(3, high: 8, low: 6),
        candle(2, high: 20, low: 2),
        candle(1, high: 15, low: 7),
        candle(0, high: 9, low: 1),
      ];

      cache.updateCandles(candles);

      final result = cache.queryByIndex(1, 3);

      expect(result.maxHigh, 20);
      expect(result.minLow, 2);
      expect(result.startTime, candles[3].date);
      expect(result.endTime, candles[1].date);
    });

    test('updates latest candle without changing length', () {
      final cache = MinMaxCache(rangeSize: 3);

      final oldCandles = [
        candle(3, high: 10, low: 5),
        candle(2, high: 8, low: 4),
        candle(1, high: 7, low: 3),
      ];

      cache.updateCandles(oldCandles);

      final newCandles = [
        candle(3, high: 100, low: -10), // same time, updated values
        candle(2, high: 8, low: 4),
        candle(1, high: 7, low: 3),
      ];

      cache.updateCandles(newCandles);

      final result = cache.queryByIndex(0, 2);

      expect(result.maxHigh, 100);
      expect(result.minLow, -10);
    });

    test('prepends new candles at front', () {
      final cache = MinMaxCache(rangeSize: 3);

      final oldCandles = [
        candle(3, high: 10, low: 5),
        candle(2, high: 8, low: 4),
        candle(1, high: 7, low: 3),
      ];

      cache.updateCandles(oldCandles);

      final newCandles = [
        candle(5, high: 50, low: 6),
        candle(4, high: 40, low: 2),
        candle(3, high: 10, low: 5),
        candle(2, high: 8, low: 4),
        candle(1, high: 7, low: 3),
      ];

      cache.updateCandles(newCandles);

      final result = cache.queryByIndex(0, 4);

      expect(result.maxHigh, 50);
      expect(result.minLow, 2);
      expect(cache.candles.length, 5);
    });

    test('updates previous latest and prepends new candles together', () {
      final cache = MinMaxCache(rangeSize: 3);

      final oldCandles = [
        candle(3, high: 10, low: 5),
        candle(2, high: 8, low: 4),
        candle(1, high: 7, low: 3),
      ];

      cache.updateCandles(oldCandles);

      final newCandles = [
        candle(4, high: 40, low: 6),
        candle(3, high: 100, low: -5), // updated old latest
        candle(2, high: 8, low: 4),
        candle(1, high: 7, low: 3),
      ];

      cache.updateCandles(newCandles);

      final result = cache.queryByIndex(0, 3);

      expect(result.maxHigh, 100);
      expect(result.minLow, -5);
    });

    test('appends old history candles at end', () {
      final cache = MinMaxCache(rangeSize: 3);

      final oldCandles = [
        candle(3, high: 10, low: 5),
        candle(2, high: 8, low: 4),
        candle(1, high: 7, low: 3),
      ];

      cache.updateCandles(oldCandles);

      final newCandles = [
        candle(3, high: 10, low: 5),
        candle(2, high: 8, low: 4),
        candle(1, high: 7, low: 3),
        candle(0, high: 30, low: -20),
      ];

      cache.updateCandles(newCandles);

      final result = cache.queryByIndex(0, 3);

      expect(result.maxHigh, 30);
      expect(result.minLow, -20);
      expect(cache.candles.length, 4);
    });

    test('handles front update, latest update, and history append together',
        () {
      final cache = MinMaxCache(rangeSize: 3);

      final oldCandles = [
        candle(3, high: 10, low: 5),
        candle(2, high: 8, low: 4),
        candle(1, high: 7, low: 3),
      ];

      cache.updateCandles(oldCandles);

      final newCandles = [
        candle(5, high: 50, low: 6),
        candle(4, high: 40, low: 2),
        candle(3, high: 100, low: -5), // updated old latest
        candle(2, high: 8, low: 4),
        candle(1, high: 7, low: 3),
        candle(0, high: 30, low: -20),
      ];

      cache.updateCandles(newCandles);

      final result = cache.queryByIndex(0, 5);

      expect(result.maxHigh, 100);
      expect(result.minLow, -20);
      expect(cache.candles.length, 6);
    });

    test('clamps invalid indexes', () {
      final cache = MinMaxCache(rangeSize: 3);

      final candles = [
        candle(2, high: 10, low: 5),
        candle(1, high: 20, low: 2),
        candle(0, high: 15, low: 1),
      ];

      cache.updateCandles(candles);

      final result = cache.queryByIndex(-100, 100);

      expect(result.maxHigh, 20);
      expect(result.minLow, 1);
    });

    test('handles reversed indexes', () {
      final cache = MinMaxCache(rangeSize: 3);

      final candles = [
        candle(2, high: 10, low: 5),
        candle(1, high: 20, low: 2),
        candle(0, high: 15, low: 1),
      ];

      cache.updateCandles(candles);

      final result = cache.queryByIndex(2, 0);

      expect(result.maxHigh, 20);
      expect(result.minLow, 1);
    });

    test('clears cache when empty list is passed', () {
      final cache = MinMaxCache(rangeSize: 3);

      cache.updateCandles([
        candle(1, high: 10, low: 5),
      ]);

      cache.updateCandles([]);

      expect(cache.candles, isEmpty);
      expect(cache.ranges, isEmpty);
    });
  });
}
