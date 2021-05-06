# candlesticks

A flutter candlesticks chart for android, ios and the web; It contains optimized animations indicators and socket connection ability.

![Gif](https://github.com/r-mzy47/candlesticks/blob/master/example.gif "bictoin daily chart 2017 - 2020")

## Installation

1. Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  candlesticks: ^0.4.0
```

2. Get the package using your IDE's GUI or via command line with

```bash
$ flutter pub get
```

## Usage

```dart
import 'package:candlesticks/candlesticks.dart';
```

### Candle

[Candle] class contains five required double variables that hold a single candle data: high, low, open, close and volume.
It can be instantiated using its default constructor or fromJson named custructor.

```dart
final candle =  Candle(open: 1780.36, high: 1873.93, low: 1755.34, close: 1848.56, volume: 0);
```

### Candlesticks

[Candlesticks] widget requires only a list of candles. And that's it. It is recommended to wrap [Candlesticks] with the [AspectRatio] widget.