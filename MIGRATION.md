# Migration Guide: 2.x to 3.0.0

This guide explains how to migrate from `candlesticks` version `2.x` to `3.0.0`.

Version `3.0.0` is a major release with breaking API changes. The main goals of this release are:

- cleaner public API
- better separation between chart rendering and app-specific logic
- controller-based chart control
- improved styling API
- better support for custom chart UI

## Update the dependency

Update your `pubspec.yaml`:

```yaml
dependencies:
  candlesticks: ^3.0.0
```

Then run:

```bash
flutter pub get
```

## Breaking changes

## 1. Remove `actions` from `Candlesticks`

In `2.x`, `Candlesticks` had a built-in toolbar and accepted custom toolbar actions.

### Before

```dart
Candlesticks(
  candles: candles,
  actions: [
    ToolBarAction(
      child: const Text('1h'),
      onPressed: () {},
    ),
  ],
)
```

In `3.0.0`, the `actions` parameter has been removed. The chart no longer owns your toolbar UI.

### After

Move toolbar buttons outside the chart:

```dart
Column(
  children: [
    Row(
      children: [
        TextButton(
          onPressed: () {
            // Change interval in your app.
          },
          child: const Text('1h'),
        ),
      ],
    ),
    Expanded(
      child: Candlesticks(
        candles: candles,
      ),
    ),
  ],
)
```

This gives your app full control over toolbar layout, styling, and behavior.

## 2. Replace `ToolBarAction` with normal Flutter widgets

`ToolBarAction` is no longer part of the public API.

### Before

```dart
ToolBarAction(
  child: const Text('1D'),
  onPressed: () {},
)
```

### After

Use normal Flutter widgets instead:

```dart
TextButton(
  onPressed: () {},
  child: const Text('1D'),
)
```

or:

```dart
IconButton(
  onPressed: () {},
  icon: const Icon(Icons.zoom_in),
)
```

## 3. Replace theme extension colors with `CandleSticksStyle`

In `2.x`, chart colors were taken from internal theme extension getters, and users could not customize them directly from the `Candlesticks` widget.

In `3.0.0`, chart colors are configured with `CandleSticksStyle`.

### Basic usage

```dart
Candlesticks(
  candles: candles,
  style: CandleSticksStyle.dark(),
)
```

or:

```dart
Candlesticks(
  candles: candles,
  style: CandleSticksStyle.light(),
)
```

If `style` is not provided, the chart chooses `CandleSticksStyle.dark()` or `CandleSticksStyle.light()` based on the current Flutter theme brightness.

### Custom style

```dart
Candlesticks(
  candles: candles,
  style: CandleSticksStyle.dark(
    chartBackgroundColor: const Color(0xFF0F0F0F),
    gridLineColor: const Color(0xFF1C1C1C),
    axisTextColor: const Color(0xFF848E9C),
    candleBullColor: const Color(0xFF26A69A),
    candleBearColor: const Color(0xFFEF5350),
    volumeBullColor: const Color(0xFF005940),
    volumeBearColor: const Color(0xFF82122B),
    crosshairLineColor: const Color(0xFF848E9C),
    crosshairLabelBackgroundColor: const Color(0xFF4C525E),
    crosshairLabelTextColor: const Color(0xFFFFFFFF),
    priceIndicatorTextColor: const Color(0xFFFFFFFF),
    loadingIndicatorColor: const Color(0xFFF0B90A),
  ),
)
```

## 4. Update `Candle.fromJson`

In `2.x`, `Candle.fromJson` accepted a `List<dynamic>`.

### Before

```dart
final candle = Candle.fromJson([
  1715731200000,
  '100.0',
  '120.0',
  '90.0',
  '110.0',
  '5000.0',
]);
```

In `3.0.0`, `Candle.fromJson` expects a `Map<String, dynamic>`.

### After

```dart
final candle = Candle.fromJson({
  'date': 1715731200000,
  'open': 100.0,
  'high': 120.0,
  'low': 90.0,
  'close': 110.0,
  'volume': 5000.0,
});
```

The `date` value must be milliseconds since the Unix epoch.

This makes candle serialization clearer and independent from any specific data source.

## 5. Use `CandlesticksController` for external chart control

In `2.x`, scroll index and candle width were internal chart state.

In `3.0.0`, you can control the chart with `CandlesticksController`.

```dart
class ChartPageState extends State<ChartPage> {
  final controller = CandlesticksController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Candlesticks(
      candles: candles,
      controller: controller,
    );
  }
}
```

You can use the controller to zoom or move the chart:

```dart
controller.zoomIn();
controller.zoomOut();
controller.zoomBy(1.2);
controller.setZoom(8);
controller.jumpTo(0);
controller.animateTo(20);
controller.jumpToCandle(20);
```

Example with buttons:

```dart
Column(
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
      ],
    ),
  ],
)
```

## 6. Use `loadingWidget` for empty data

In `3.0.0`, if `candles` is empty, the chart shows a loading indicator by default.

```dart
Candlesticks(
  candles: const [],
)
```

You can customize the empty/loading state with `loadingWidget`:

```dart
Candlesticks(
  candles: const [],
  loadingWidget: const Center(
    child: Text('Loading candles...'),
  ),
)
```

## 7. Candle order is unchanged

The candle list must still be ordered from newest to oldest.

The newest candle should be at index `0`.

```dart
final candles = [
  newestCandle,
  previousCandle,
  olderCandle,
];
```

When loading older candles, append them to the end of the list:

```dart
setState(() {
  candles.addAll(olderCandles);
});
```

## 8. `onLoadMoreCandles` still exists

You can still use `onLoadMoreCandles` to load older candles.

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

The callback is called when the user scrolls close to the oldest loaded candle.

The widget prevents overlapping calls while a previous load operation is still running.

## 9. Minimal migrated example

```dart
import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final controller = CandlesticksController();

  List<Candle> candles = [];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> loadMoreCandles() async {
    final olderCandles = await fetchOlderCandles();

    setState(() {
      candles.addAll(olderCandles);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (candles.length == 1) {
      return const Center(
        child: Text('Not enough candle data'),
      );
    }

    return Column(
      children: [
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
          ],
        ),
        Expanded(
          child: Candlesticks(
            candles: candles,
            controller: controller,
            onLoadMoreCandles: loadMoreCandles,
            style: CandleSticksStyle.dark(),
          ),
        ),
      ],
    );
  }
}
```

checkout https://github.com/r-mzy47/candlesticks/tree/master/example
