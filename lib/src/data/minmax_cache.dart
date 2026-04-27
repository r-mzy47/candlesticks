import 'dart:math';
import '../models/candle.dart';

class RangeMinMax {
  final DateTime startTime;
  final DateTime endTime;
  final double minLow;
  final double maxHigh;

  const RangeMinMax({
    required this.startTime,
    required this.endTime,
    required this.minLow,
    required this.maxHigh,
  });

  bool isOutside(DateTime from, DateTime to) {
    return endTime.isBefore(from) || startTime.isAfter(to);
  }

  bool isInside(DateTime from, DateTime to) {
    return !startTime.isBefore(from) && !endTime.isAfter(to);
  }
}

class CandleRange extends RangeMinMax {
  final List<Candle> candles;

  const CandleRange({
    required this.candles,
    required super.startTime,
    required super.endTime,
    required super.minLow,
    required super.maxHigh,
  });
}

class MinMaxCache {
  final int rangeSize;

  List<Candle> _candles = [];
  final List<CandleRange> _ranges = [];

  MinMaxCache({
    this.rangeSize = 50,
  });

  List<Candle> get candles => _candles;
  List<CandleRange> get ranges => _ranges;

  /// Main method.
  ///
  /// Supports:
  /// - latest candle update
  /// - new candles added at front
  /// - old history added at end
  /// - all of them together
  void updateCandles(List<Candle> newCandles) {
    if (newCandles.isEmpty) {
      _candles.clear();
      _ranges.clear();
      return;
    }

    if (_candles.isEmpty) {
      _setInitialCandles(newCandles);
      return;
    }

    final oldLength = _candles.length;
    final newLength = newCandles.length;

    if (newLength < oldLength) {
      _setInitialCandles(newCandles);
      return;
    }

    final addedCount = newLength - oldLength;

    final oldNewestTime = _candles.first.date;
    final oldOldestTime = _candles.last.date;

    int frontAdded = 0;

    // Search only inside the added area.
    // This is O(addedCount), not O(n).
    while (frontAdded <= addedCount &&
        newCandles[frontAdded].date != oldNewestTime) {
      frontAdded++;
    }

    // Could not find old newest candle in expected place.
    if (frontAdded > addedCount) {
      _setInitialCandles(newCandles);
      return;
    }

    final backAdded = addedCount - frontAdded;
    final oldOldestIndexInNew = frontAdded + oldLength - 1;

    // Make sure old data still matches.
    // Otherwise data was changed/reordered/deleted.
    if (newCandles[oldOldestIndexInNew].date != oldOldestTime) {
      _setInitialCandles(newCandles);
      return;
    }

    // 1. Update previous newest candle.
    //
    // Example:
    // old: [A, B, C]
    // new: [A', B, C]
    //
    // or:
    // old: [A, B, C]
    // new: [X, A', B, C]
    final updatedOldNewest = newCandles[frontAdded];

    _candles[0] = updatedOldNewest;
    _replaceFirstCandleInFirstRange(updatedOldNewest);

    // 2. Add new candles at front.
    //
    // Example:
    // old: [A, B, C]
    // new: [X, A', B, C]
    if (frontAdded > 0) {
      final addedFront = newCandles.sublist(0, frontAdded);
      _prependNewCandles(addedFront);
    }

    // 3. Add older history at end.
    //
    // Example:
    // old: [A, B, C]
    // new: [X, A', B, C, D, E]
    if (backAdded > 0) {
      final addedBack = newCandles.sublist(newLength - backAdded);
      _appendOldCandles(addedBack);
    }
  }

  /// Query visible chart area using indexes.
  RangeMinMax queryByIndex(int left, int right) {
    if (_candles.isEmpty) {
      final zero = DateTime.fromMillisecondsSinceEpoch(0);
      return RangeMinMax(
        startTime: zero,
        endTime: zero,
        minLow: 0,
        maxHigh: 0,
      );
    }

    left = left.clamp(0, _candles.length - 1);
    right = right.clamp(0, _candles.length - 1);

    if (left > right) {
      final tmp = left;
      left = right;
      right = tmp;
    }

    final from = _candles[right].date;
    final to = _candles[left].date;

    return queryByTime(from, to);
  }

  /// Query using time range.
  RangeMinMax queryByTime(DateTime from, DateTime to) {
    if (from.isAfter(to)) {
      final tmp = from;
      from = to;
      to = tmp;
    }

    double minLow = double.infinity;
    double maxHigh = -double.infinity;

    for (final range in _ranges) {
      if (range.isOutside(from, to)) {
        continue;
      }

      if (range.isInside(from, to)) {
        minLow = min(minLow, range.minLow);
        maxHigh = max(maxHigh, range.maxHigh);
      } else {
        for (final candle in range.candles) {
          if (!_isInside(candle.date, from, to)) continue;

          minLow = min(minLow, candle.low);
          maxHigh = max(maxHigh, candle.high);
        }
      }
    }

    if (minLow == double.infinity) {
      return RangeMinMax(
        startTime: from,
        endTime: to,
        minLow: 0,
        maxHigh: 0,
      );
    }

    return RangeMinMax(
      startTime: from,
      endTime: to,
      minLow: minLow,
      maxHigh: maxHigh,
    );
  }

  /// First load / fallback rebuild.
  void _setInitialCandles(List<Candle> candles) {
    _candles = List.of(candles);
    _ranges.clear();

    for (int i = 0; i < _candles.length; i += rangeSize) {
      final end = min(i + rangeSize, _candles.length);
      final chunk = _candles.sublist(i, end);
      _ranges.add(_calculateRange(chunk));
    }
  }

  /// Replace the first candle inside range[0].
  ///
  /// Used when latest candle changes.
  void _replaceFirstCandleInFirstRange(Candle candle) {
    if (_ranges.isEmpty) return;

    final firstRange = _ranges.first;

    if (firstRange.candles.isEmpty) return;

    final updatedCandles = [
      candle,
      ...firstRange.candles.skip(1),
    ];

    _ranges[0] = _calculateRange(updatedCandles);
  }

  /// Add new candles at the front.
  ///
  /// Important:
  /// We do NOT shift all ranges.
  /// We fill range[0] if it has space.
  /// Otherwise, we create new ranges at the front.
  void _prependNewCandles(List<Candle> candles) {
    if (candles.isEmpty) return;

    _candles.insertAll(0, candles);

    var remaining = List<Candle>.of(candles);

    while (remaining.isNotEmpty) {
      if (_ranges.isEmpty) {
        final take = min(rangeSize, remaining.length);
        final chunk = remaining.sublist(0, take);

        _ranges.insert(0, _calculateRange(chunk));
        remaining = remaining.sublist(take);
        continue;
      }

      final firstRange = _ranges.first;
      final freeSpace = rangeSize - firstRange.candles.length;

      if (freeSpace > 0) {
        final take = min(freeSpace, remaining.length);

        // Take from the END of remaining so order stays correct.
        //
        // Example:
        // remaining: [X, Y]
        // old first range: [A, B]
        // result should be [X, Y, A, B]
        final toAdd = remaining.sublist(remaining.length - take);

        final updatedCandles = [
          ...toAdd,
          ...firstRange.candles,
        ];

        _ranges[0] = _calculateRange(updatedCandles);

        remaining = remaining.sublist(0, remaining.length - take);
      } else {
        final take = min(rangeSize, remaining.length);

        // Create new front range from the END of remaining.
        final chunk = remaining.sublist(remaining.length - take);

        _ranges.insert(0, _calculateRange(chunk));

        remaining = remaining.sublist(0, remaining.length - take);
      }
    }
  }

  /// Add old history candles at the end.
  ///
  /// We fill the last range if it has space.
  /// Otherwise, we create new ranges at the end.
  void _appendOldCandles(List<Candle> candles) {
    if (candles.isEmpty) return;

    _candles.addAll(candles);

    var remaining = List<Candle>.of(candles);

    while (remaining.isNotEmpty) {
      if (_ranges.isEmpty) {
        final take = min(rangeSize, remaining.length);
        final chunk = remaining.sublist(0, take);

        _ranges.add(_calculateRange(chunk));
        remaining = remaining.sublist(take);
        continue;
      }

      final lastRange = _ranges.last;
      final freeSpace = rangeSize - lastRange.candles.length;

      if (freeSpace > 0) {
        final take = min(freeSpace, remaining.length);

        final toAdd = remaining.sublist(0, take);

        final updatedCandles = [
          ...lastRange.candles,
          ...toAdd,
        ];

        _ranges[_ranges.length - 1] = _calculateRange(updatedCandles);

        remaining = remaining.sublist(take);
      } else {
        final take = min(rangeSize, remaining.length);
        final chunk = remaining.sublist(0, take);

        _ranges.add(_calculateRange(chunk));

        remaining = remaining.sublist(take);
      }
    }
  }

  CandleRange _calculateRange(List<Candle> candles) {
    DateTime startTime = candles.first.date;
    DateTime endTime = candles.first.date;

    double minLow = double.infinity;
    double maxHigh = -double.infinity;

    for (final candle in candles) {
      if (candle.date.isBefore(startTime)) {
        startTime = candle.date;
      }

      if (candle.date.isAfter(endTime)) {
        endTime = candle.date;
      }

      minLow = min(minLow, candle.low);
      maxHigh = max(maxHigh, candle.high);
    }

    return CandleRange(
      candles: List.of(candles),
      startTime: startTime,
      endTime: endTime,
      minLow: minLow,
      maxHigh: maxHigh,
    );
  }

  bool _isInside(DateTime time, DateTime from, DateTime to) {
    return !time.isBefore(from) && !time.isAfter(to);
  }
}
