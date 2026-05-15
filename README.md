
<h1 align="center">Candlesticks</h1>

<p align="center">
  <b>A high-performance, interactive Flutter candlestick chart for financial apps.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/version-3.0.0-5FC9F8" alt="Version 3.0.0">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-supported-02569B?logo=apple&logoColor=white" alt="iOS supported">
  <img src="https://img.shields.io/badge/Android-supported-3DDC84?logo=android&logoColor=white" alt="Android supported">
  <img src="https://img.shields.io/badge/Web-supported-0175C2?logo=googlechrome&logoColor=white" alt="Web supported">
  <img src="https://img.shields.io/badge/macOS-supported-02569B?logo=apple&logoColor=white" alt="macOS supported">
  <img src="https://img.shields.io/badge/Windows-supported-0078D4?logo=windows&logoColor=white" alt="Windows supported">
  <img src="https://img.shields.io/badge/Linux-supported-FCC624?logo=linux&logoColor=black" alt="Linux supported">
</p>

<p align="center">
  <a href="https://r-mzy47.github.io/candlesticks/master/">Web Demo</a>
  ·
  <a href="https://pub.dev/packages/candlesticks">pub.dev</a>
  ·
  <a href="https://github.com/r-mzy47/candlesticks">GitHub</a>
</p>


---

`candlesticks` is a Flutter package for rendering interactive OHLCV candlestick charts.

It supports mobile and desktop gestures, crosshair interaction, panning, zooming, logarithmic and linear scale toggling, volume bars, controller-based viewport control, lazy loading, and custom chart styling.

## Preview

### Web Preview

Try the live web example:

[https://r-mzy47.github.io/candlesticks/master/](https://r-mzy47.github.io/candlesticks/master/)

### Mobile Preview

|  |  |
|---|---|
| **Logarithmic and linear scales**<br><img src="https://raw.githubusercontent.com/r-mzy47/candlesticks/master/docs/assets/1.gif" width="360" alt="Logarithmic and linear scale demo"><br> | **Long press for crosshair**<br><img src="https://raw.githubusercontent.com/r-mzy47/candlesticks/master/docs/assets/2.gif" width="360" alt="Long press crosshair demo"><br> |
| **Advanced gestures: pan in any direction**<br><img src="https://raw.githubusercontent.com/r-mzy47/candlesticks/master/docs/assets/3.gif" width="360" alt="Advanced chart gesture demo"><br> | **Anchored and regular zoom**<br><img src="https://raw.githubusercontent.com/r-mzy47/candlesticks/master/docs/assets/4.gif" width="360" alt="Anchored and regular zoom demo"><br> |

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  candlesticks: ^3.0.0
```

Then run:

```bash
flutter pub get
```

## Import

```dart
import 'package:candlesticks/candlesticks.dart';
```

## Basic Usage

```dart
import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';

class ChartPage extends StatelessWidget {
  const ChartPage({super.key});

  List<Candle> get candles {
    return [
      Candle(
        date: DateTime(2024, 1, 2),
        open: 105,
        high: 115,
        low: 101,
        close: 108,
        volume: 1500,
      ),
      Candle(
        date: DateTime(2024, 1, 1),
        open: 100,
        high: 110,
        low: 95,
        close: 105,
        volume: 1200,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Candlesticks(
          candles: candles,
        ),
      ),
    );
  }
}
```

> The candle list must be ordered from newest to oldest.  
> The newest candle should be at index `0`.

```dart
final candles = [
  newestCandle,
  previousCandle,
  olderCandle,
];
```

## Candle Model

`Candle` represents one OHLCV data point.

```dart
final candle = Candle(
  date: DateTime.now(),
  open: 100,
  high: 120,
  low: 90,
  close: 110,
  volume: 5000,
);
```

### Candle Fields

| Field | Type | Description |
|---|---|---|
| `date` | `DateTime` | Candle timestamp. Usually the opening time of the candle interval. |
| `open` | `double` | Opening price. |
| `high` | `double` | Highest price during the candle period. |
| `low` | `double` | Lowest price during the candle period. |
| `close` | `double` | Closing price. |
| `volume` | `double` | Traded volume. |
| `isBull` | `bool` | Returns `true` when `open <= close`. |


## Parsing API Data

The package focuses on chart rendering. Exchange-specific parsing should be handled in your own app or repository layer.

Example for Binance kline data:

```dart
Candle candleFromBinanceKline(List<dynamic> json) {
  return Candle(
    date: DateTime.fromMillisecondsSinceEpoch(json[0] as int),
    open: double.parse(json[1] as String),
    high: double.parse(json[2] as String),
    low: double.parse(json[3] as String),
    close: double.parse(json[4] as String),
    volume: double.parse(json[5] as String),
  );
}
```

## Candlesticks Widget

```dart
Candlesticks(
  candles: candles,
)
```

### Constructor

```dart
const Candlesticks({
  super.key,
  required this.candles,
  this.onLoadMoreCandles,
  this.chartAdjust = ChartAdjust.visibleRange,
  this.loadingWidget,
  this.controller,
  this.style,
});
```

### Properties

| Property | Type | Description |
|---|---|---|
| `candles` | `List<Candle>` | Candle data. The list must be ordered from newest to oldest. |
| `onLoadMoreCandles` | `Future<void> Function()?` | Called when the chart scroll position is close to the oldest loaded candle. |
| `chartAdjust` | `ChartAdjust` | Defines how the chart price range is calculated. |
| `loadingWidget` | `Widget?` | Widget displayed when `candles` is empty. |
| `controller` | `CandlesticksController?` | Optional controller for programmatic viewport control. |
| `style` | `CandleSticksStyle?` | Optional visual style for the chart. |

### Loading State

When `candles` is empty, the chart shows a loading indicator by default.

```dart
Candlesticks(
  candles: const [],
)
```

Use `loadingWidget` to customize it:

```dart
Candlesticks(
  candles: const [],
  loadingWidget: const Text('Loading candles...'),
)
```

### Load More Candles

Use `onLoadMoreCandles` to fetch older candles when the user scrolls near the end of the loaded history.

```dart
Candlesticks(
  candles: candles,
  onLoadMoreCandles: () async {
    final olderCandles = await repository.fetchOlderCandles();

    setState(() {
      candles.addAll(olderCandles);
    });
  },
)
```

Older candles should be added to the end of the list.

```dart
candles = [
  newestCandle,
  previousCandle,
  olderCandle,
  evenOlderCandle,
];
```

### Chart Range Adjustment

`chartAdjust` controls how the vertical price range is calculated.

```dart
Candlesticks(
  candles: candles,
  chartAdjust: ChartAdjust.visibleRange,
)
```

Available values:

```dart
ChartAdjust.visibleRange
ChartAdjust.fullRange
```

#### `ChartAdjust.visibleRange`

Calculates the chart price range from the currently visible candles.

This keeps the chart vertically focused on the visible data while the user scrolls.

```dart
Candlesticks(
  candles: candles,
  chartAdjust: ChartAdjust.visibleRange,
)
```

#### `ChartAdjust.fullRange`

Calculates the chart price range from the full candle list.

This keeps the vertical scale more stable while scrolling, but smaller visible price movements may be harder to see.

```dart
Candlesticks(
  candles: candles,
  chartAdjust: ChartAdjust.fullRange,
)
```

### Controller

Use `CandlesticksController` when you want to control the chart viewport manually.

```dart
final controller = CandlesticksController();
```

```dart
Candlesticks(
  candles: candles,
  controller: controller,
)
```

Dispose the controller if you create it inside a `State` object:

```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

#### Controller Example

```dart
class ControlledChartPage extends StatefulWidget {
  const ControlledChartPage({super.key});

  @override
  State<ControlledChartPage> createState() => _ControlledChartPageState();
}

class _ControlledChartPageState extends State<ControlledChartPage> {
  final CandlesticksController controller = CandlesticksController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Candlesticks(
            candles: candles,
            controller: controller,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: controller.zoomIn,
              icon: const Icon(Icons.zoom_in),
            ),
            IconButton(
              onPressed: controller.zoomOut,
              icon: const Icon(Icons.zoom_out),
            ),
            IconButton(
              onPressed: () => controller.animateTo(-10),
              icon: const Icon(Icons.keyboard_double_arrow_right),
            ),
          ],
        ),
      ],
    );
  }
}
```

#### Common Controller Members

| Member | Description |
|---|---|
| `isNearEnd` | Whether the visible range is close to the oldest loaded candle. |
| `jumpTo(double index)` | Jumps to a scroll index without animation. |
| `animateTo(double index)` | Animates to a scroll index. |
| `setZoom(double width)` | Sets candle width directly. |
| `zoomBy(double factor)` | Multiplies the current candle width by a factor. |
| `zoomIn()` | Zooms in by a fixed step. |
| `zoomOut()` | Zooms out by a fixed step. |
| `scrollByPixels(...)` | Scrolls horizontally by a pixel delta. |

## Styling

By default, the chart chooses a light or dark style based on the current Flutter theme.

```dart
Candlesticks(
  candles: candles,
)
```

You can pass your own style:

```dart
Candlesticks(
  candles: candles,
  style: CandleSticksStyle.dark(
    chartBackgroundColor: const Color(0xFF0F0F0F),
    candleBullColor: const Color(0xFF26A69A),
    candleBearColor: const Color(0xFFEF5350),
  ),
)
```

Or use the light style:

```dart
Candlesticks(
  candles: candles,
  style: CandleSticksStyle.light(),
)
```

### Style Fields

| Field | Description |
|---|---|
| `chartBackgroundColor` | Main chart background. |
| `gridLineColor` | Horizontal and vertical grid lines. |
| `axisTextColor` | Price and time axis text. |
| `candleBullColor` | Bullish candle body and wick. |
| `candleBearColor` | Bearish candle body and wick. |
| `volumeBullColor` | Bullish volume bar. |
| `volumeBearColor` | Bearish volume bar. |
| `crosshairLineColor` | Dashed crosshair line. |
| `crosshairLabelBackgroundColor` | Crosshair price/time label background. |
| `crosshairLabelTextColor` | Crosshair price/time label text. |
| `ohlcInfoTextColor` | OHLC info label text. |
| `ohlcInfoBullColor` | Bullish OHLC value text. |
| `ohlcInfoBearColor` | Bearish OHLC value text. |
| `priceIndicatorBullBackgroundColor` | Last price label background when the latest candle is bullish. |
| `priceIndicatorBearBackgroundColor` | Last price label background when the latest candle is bearish. |
| `priceIndicatorTextColor` | Last price label text. |
| `scaleButtonActiveBackgroundColor` | Active scale button background. |
| `scaleButtonActiveTextColor` | Active scale button text. |
| `scaleButtonInactiveBackgroundColor` | Inactive scale button background. |
| `scaleButtonInactiveTextColor` | Inactive scale button text. |
| `loadingIndicatorColor` | Default loading indicator color. |


## Example App

The repository includes a complete example app that demonstrates the core features of this package in a real project.

The example app is connected to the Binance API and includes:

- Symbol search
- Timeframe selection
- Historical candle loading
- Real-time price updates
- Chart zooming and panning
- Logarithmic and linear scale toggling
- Mobile and desktop gesture support

Run it locally:

```bash
cd example
flutter run
```

Run it on web:

```bash
cd example
flutter run -d chrome
```

Live web example:

[https://r-mzy47.github.io/candlesticks/master/](https://r-mzy47.github.io/candlesticks/master/)

## Migration Guide

See [MIGRATION.md](MIGRATION.md) for the migration guide from version `2.x` to version `3.0.0`.
