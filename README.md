# candlesticks

[![pub package](https://img.shields.io/badge/pub-v2.0.1-orange.svg)](https://pub.dev/packages/candlesticks)

A high-performance full featured candlesticks chart for all platforms!

web demo:</br>
[Binance Candles](https://rmzy.dev/candlesticks/)</br>
[Binance Candles Github Repository](https://github.com/r-mzy47/binance_candles)

## Preview
|IOS	|macOS		|
|:------------:|:------------:|
|	[![](https://github.com/r-mzy47/candlesticks/blob/develop/example_ios.gif)](https://github.com/r-mzy47/candlesticks/blob/master/example/lib/main.dart)   |	[![](https://github.com/r-mzy47/candlesticks/blob/develop/example_macOS.gif)](https://github.com/r-mzy47/candlesticks/blob/master/example/lib/main.dart) | 

## Installation

1. Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  candlesticks: ^2.1.0
```

2. Get the package using your IDE's GUI or via command line with

```bash
$ flutter pub get
```

## Usage

```dart
import 'package:candlesticks/candlesticks_plus.dart';
```

### Candle

[Candle] class contains six required variables that hold a single candle data: date, high, low, open, close and volume.

```dart
final candle =  Candle(date: DateTime.now(), open: 1780.36, high: 1873.93, low: 1755.34, close: 1848.56, volume: 0);
```

### Candlesticks

[Candlesticks] widget requires a list of candles, the arrangement of the `candles` array should be such that the newest item is in position 0, `onLoadMoreCandles` is a nullable callback which calls whenever the last candle gets visible. and in case you whant to add more actions in top toolbar like [Binance Candles](https://rmzy.dev/candlesticks/), you can make your custom [ToolBarAction] and add it to `actions` parameter.

🍺 pull requests are welcome!
