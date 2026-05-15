import 'package:flutter_test/flutter_test.dart';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/data/minmax_cache.dart';

void main() {
  Candle candle(
    int minute, {
    required double high,
    required double low,
    double volume = 0,
  }) {
    return Candle(
      date: DateTime(2024, 1, 1, 0, minute),
      high: high,
      low: low,
      open: 0,
      close: 0,
      volume: volume,
    );
  }

  group('CandleMinMaxCache', () {
    test('builds initial ranges and queries full range', () {
      final cache = MinMaxCache(rangeSize: 3);

      final candles = [
        candle(5, high: 10, low: 5, volume: 50),
        candle(4, high: 12, low: 4, volume: 40),
        candle(3, high: 8, low: 6, volume: 30),
        candle(2, high: 20, low: 2, volume: 60),
        candle(1, high: 15, low: 7, volume: 20),
        candle(0, high: 9, low: 1, volume: 10),
      ];

      cache.updateCandles(candles);

      final result = cache.queryByIndex(0, 5);

      expect(result.maxHigh, 20);
      expect(result.minLow, 1);
      expect(result.maxVolume, 60);
      expect(result.startTime, candles[5].date);
      expect(result.endTime, candles[0].date);
    });

    test('queries partial range correctly', () {
      final cache = MinMaxCache(rangeSize: 3);

      final candles = [
        candle(5, high: 10, low: 5, volume: 50),
        candle(4, high: 12, low: 4, volume: 40),
        candle(3, high: 8, low: 6, volume: 30),
        candle(2, high: 20, low: 2, volume: 60),
        candle(1, high: 15, low: 7, volume: 20),
        candle(0, high: 9, low: 1, volume: 10),
      ];

      cache.updateCandles(candles);

      final result = cache.queryByIndex(1, 3);

      expect(result.maxHigh, 20);
      expect(result.minLow, 2);
      expect(result.maxVolume, 60);
      expect(result.startTime, candles[3].date);
      expect(result.endTime, candles[1].date);
    });

    test('updates latest candle without changing length', () {
      final cache = MinMaxCache(rangeSize: 3);

      final oldCandles = [
        candle(3, high: 10, low: 5, volume: 10),
        candle(2, high: 8, low: 4, volume: 8),
        candle(1, high: 7, low: 3, volume: 7),
      ];

      cache.updateCandles(oldCandles);

      final newCandles = [
        candle(3, high: 100, low: -10, volume: 1000),
        candle(2, high: 8, low: 4, volume: 8),
        candle(1, high: 7, low: 3, volume: 7),
      ];

      cache.updateCandles(newCandles);

      final result = cache.queryByIndex(0, 2);

      expect(result.maxHigh, 100);
      expect(result.minLow, -10);
      expect(result.maxVolume, 1000);
    });

    test('prepends new candles at front', () {
      final cache = MinMaxCache(rangeSize: 3);

      final oldCandles = [
        candle(3, high: 10, low: 5, volume: 10),
        candle(2, high: 8, low: 4, volume: 8),
        candle(1, high: 7, low: 3, volume: 7),
      ];

      cache.updateCandles(oldCandles);

      final newCandles = [
        candle(5, high: 50, low: 6, volume: 500),
        candle(4, high: 40, low: 2, volume: 400),
        candle(3, high: 10, low: 5, volume: 10),
        candle(2, high: 8, low: 4, volume: 8),
        candle(1, high: 7, low: 3, volume: 7),
      ];

      cache.updateCandles(newCandles);

      final result = cache.queryByIndex(0, 4);

      expect(result.maxHigh, 50);
      expect(result.minLow, 2);
      expect(result.maxVolume, 500);
      expect(cache.candles.length, 5);
    });

    test('updates previous latest and prepends new candles together', () {
      final cache = MinMaxCache(rangeSize: 3);

      final oldCandles = [
        candle(3, high: 10, low: 5, volume: 10),
        candle(2, high: 8, low: 4, volume: 8),
        candle(1, high: 7, low: 3, volume: 7),
      ];

      cache.updateCandles(oldCandles);

      final newCandles = [
        candle(4, high: 40, low: 6, volume: 400),
        candle(3, high: 100, low: -5, volume: 1000),
        candle(2, high: 8, low: 4, volume: 8),
        candle(1, high: 7, low: 3, volume: 7),
      ];

      cache.updateCandles(newCandles);

      final result = cache.queryByIndex(0, 3);

      expect(result.maxHigh, 100);
      expect(result.minLow, -5);
      expect(result.maxVolume, 1000);
    });

    test('appends old history candles at end', () {
      final cache = MinMaxCache(rangeSize: 3);

      final oldCandles = [
        candle(3, high: 10, low: 5, volume: 10),
        candle(2, high: 8, low: 4, volume: 8),
        candle(1, high: 7, low: 3, volume: 7),
      ];

      cache.updateCandles(oldCandles);

      final newCandles = [
        candle(3, high: 10, low: 5, volume: 10),
        candle(2, high: 8, low: 4, volume: 8),
        candle(1, high: 7, low: 3, volume: 7),
        candle(0, high: 30, low: -20, volume: 300),
      ];

      cache.updateCandles(newCandles);

      final result = cache.queryByIndex(0, 3);

      expect(result.maxHigh, 30);
      expect(result.minLow, -20);
      expect(result.maxVolume, 300);
      expect(cache.candles.length, 4);
    });

    test('handles front update, latest update, and history append together',
        () {
      final cache = MinMaxCache(rangeSize: 3);

      final oldCandles = [
        candle(3, high: 10, low: 5, volume: 10),
        candle(2, high: 8, low: 4, volume: 8),
        candle(1, high: 7, low: 3, volume: 7),
      ];

      cache.updateCandles(oldCandles);

      final newCandles = [
        candle(5, high: 50, low: 6, volume: 500),
        candle(4, high: 40, low: 2, volume: 400),
        candle(3, high: 100, low: -5, volume: 1000),
        candle(2, high: 8, low: 4, volume: 8),
        candle(1, high: 7, low: 3, volume: 7),
        candle(0, high: 30, low: -20, volume: 300),
      ];

      cache.updateCandles(newCandles);

      final result = cache.queryByIndex(0, 5);

      expect(result.maxHigh, 100);
      expect(result.minLow, -20);
      expect(result.maxVolume, 1000);
      expect(cache.candles.length, 6);
    });

    test('clamps invalid indexes', () {
      final cache = MinMaxCache(rangeSize: 3);

      final candles = [
        candle(2, high: 10, low: 5, volume: 10),
        candle(1, high: 20, low: 2, volume: 200),
        candle(0, high: 15, low: 1, volume: 15),
      ];

      cache.updateCandles(candles);

      final result = cache.queryByIndex(-100, 100);

      expect(result.maxHigh, 20);
      expect(result.minLow, 1);
      expect(result.maxVolume, 200);
    });

    test('handles reversed indexes', () {
      final cache = MinMaxCache(rangeSize: 3);

      final candles = [
        candle(2, high: 10, low: 5, volume: 10),
        candle(1, high: 20, low: 2, volume: 200),
        candle(0, high: 15, low: 1, volume: 15),
      ];

      cache.updateCandles(candles);

      final result = cache.queryByIndex(2, 0);

      expect(result.maxHigh, 20);
      expect(result.minLow, 1);
      expect(result.maxVolume, 200);
    });

    test('clears cache when empty list is passed', () {
      final cache = MinMaxCache(rangeSize: 3);

      cache.updateCandles([
        candle(1, high: 10, low: 5, volume: 100),
      ]);

      cache.updateCandles([]);

      expect(cache.candles, isEmpty);
      expect(cache.ranges, isEmpty);
    });

    test('returns zero maxVolume when query has no result', () {
      final cache = MinMaxCache(rangeSize: 3);

      final result = cache.queryByTime(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 2),
      );

      expect(result.maxHigh, 0);
      expect(result.minLow, 0);
      expect(result.maxVolume, 0);
    });
  });
}
