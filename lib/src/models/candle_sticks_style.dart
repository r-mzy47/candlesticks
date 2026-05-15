import 'dart:ui';

/// Visual colors used by a [Candlesticks] chart.
///
/// Each color maps to one clear chart role. Avoid reusing one field for
/// unrelated widgets because it makes custom themes hard to understand.
class CandleSticksStyle {
  /// Main chart background.
  final Color chartBackgroundColor;

  /// Horizontal and vertical grid lines.
  final Color gridLineColor;

  /// Text used by the price and time axes.
  final Color axisTextColor;

  /// Bullish candle body and wick color.
  final Color candleBullColor;

  /// Bearish candle body and wick color.
  final Color candleBearColor;

  /// Bullish volume bar color.
  final Color volumeBullColor;

  /// Bearish volume bar color.
  final Color volumeBearColor;

  /// Dashed crosshair line color.
  final Color crosshairLineColor;

  /// Crosshair price/time label background color.
  final Color crosshairLabelBackgroundColor;

  /// Crosshair price/time label text color.
  final Color crosshairLabelTextColor;

  /// OHLC info label text color.
  final Color ohlcInfoTextColor;

  /// Bullish OHLC value text color.
  final Color ohlcInfoBullColor;

  /// Bearish OHLC value text color.
  final Color ohlcInfoBearColor;

  /// Last price label background when the latest candle is bullish.
  final Color priceIndicatorBullBackgroundColor;

  /// Last price label background when the latest candle is bearish.
  final Color priceIndicatorBearBackgroundColor;

  /// Last price label text color.
  final Color priceIndicatorTextColor;

  /// Background color for an active scale button.
  final Color scaleButtonActiveBackgroundColor;

  /// Text color for an active scale button.
  final Color scaleButtonActiveTextColor;

  /// Background color for an inactive scale button.
  final Color scaleButtonInactiveBackgroundColor;

  /// Text color for an inactive scale button.
  final Color scaleButtonInactiveTextColor;

  /// Default loading indicator color.
  final Color loadingIndicatorColor;

  const CandleSticksStyle({
    required this.chartBackgroundColor,
    required this.gridLineColor,
    required this.axisTextColor,
    required this.candleBullColor,
    required this.candleBearColor,
    required this.volumeBullColor,
    required this.volumeBearColor,
    required this.crosshairLineColor,
    required this.crosshairLabelBackgroundColor,
    required this.crosshairLabelTextColor,
    required this.ohlcInfoTextColor,
    required this.ohlcInfoBullColor,
    required this.ohlcInfoBearColor,
    required this.priceIndicatorBullBackgroundColor,
    required this.priceIndicatorBearBackgroundColor,
    required this.priceIndicatorTextColor,
    required this.scaleButtonActiveBackgroundColor,
    required this.scaleButtonActiveTextColor,
    required this.scaleButtonInactiveBackgroundColor,
    required this.scaleButtonInactiveTextColor,
    required this.loadingIndicatorColor,
  });

  factory CandleSticksStyle.dark({
    Color? chartBackgroundColor,
    Color? gridLineColor,
    Color? axisTextColor,
    Color? candleBullColor,
    Color? candleBearColor,
    Color? volumeBullColor,
    Color? volumeBearColor,
    Color? crosshairLineColor,
    Color? crosshairLabelBackgroundColor,
    Color? crosshairLabelTextColor,
    Color? ohlcInfoTextColor,
    Color? ohlcInfoBullColor,
    Color? ohlcInfoBearColor,
    Color? priceIndicatorBullBackgroundColor,
    Color? priceIndicatorBearBackgroundColor,
    Color? priceIndicatorTextColor,
    Color? scaleButtonActiveBackgroundColor,
    Color? scaleButtonActiveTextColor,
    Color? scaleButtonInactiveBackgroundColor,
    Color? scaleButtonInactiveTextColor,
    Color? loadingIndicatorColor,
  }) {
    const bull = Color(0xFF26A69A);
    const bear = Color(0xFFEF5350);
    const mutedText = Color(0xFF848E9C);
    const white = Color(0xFFFFFFFF);
    const labelBg = Color(0xFF4C525E);

    return CandleSticksStyle(
      chartBackgroundColor: chartBackgroundColor ?? const Color(0xFF0F0F0F),
      gridLineColor: gridLineColor ?? const Color(0xFF1C1C1C),
      axisTextColor: axisTextColor ?? mutedText,
      candleBullColor: candleBullColor ?? bull,
      candleBearColor: candleBearColor ?? bear,
      volumeBullColor: volumeBullColor ?? const Color(0xFF005940),
      volumeBearColor: volumeBearColor ?? const Color(0xFF82122B),
      crosshairLineColor: crosshairLineColor ?? mutedText,
      crosshairLabelBackgroundColor: crosshairLabelBackgroundColor ?? labelBg,
      crosshairLabelTextColor: crosshairLabelTextColor ?? white,
      ohlcInfoTextColor: ohlcInfoTextColor ?? mutedText,
      ohlcInfoBullColor: ohlcInfoBullColor ?? bull,
      ohlcInfoBearColor: ohlcInfoBearColor ?? bear,
      priceIndicatorBullBackgroundColor:
          priceIndicatorBullBackgroundColor ?? bull,
      priceIndicatorBearBackgroundColor:
          priceIndicatorBearBackgroundColor ?? bear,
      priceIndicatorTextColor: priceIndicatorTextColor ?? white,
      scaleButtonActiveBackgroundColor:
          scaleButtonActiveBackgroundColor ?? labelBg,
      scaleButtonActiveTextColor: scaleButtonActiveTextColor ?? white,
      scaleButtonInactiveBackgroundColor:
          scaleButtonInactiveBackgroundColor ?? white,
      scaleButtonInactiveTextColor: scaleButtonInactiveTextColor ?? labelBg,
      loadingIndicatorColor: loadingIndicatorColor ?? const Color(0xFFF0B90A),
    );
  }

  factory CandleSticksStyle.light({
    Color? chartBackgroundColor,
    Color? gridLineColor,
    Color? axisTextColor,
    Color? candleBullColor,
    Color? candleBearColor,
    Color? volumeBullColor,
    Color? volumeBearColor,
    Color? crosshairLineColor,
    Color? crosshairLabelBackgroundColor,
    Color? crosshairLabelTextColor,
    Color? ohlcInfoTextColor,
    Color? ohlcInfoBullColor,
    Color? ohlcInfoBearColor,
    Color? priceIndicatorBullBackgroundColor,
    Color? priceIndicatorBearBackgroundColor,
    Color? priceIndicatorTextColor,
    Color? scaleButtonActiveBackgroundColor,
    Color? scaleButtonActiveTextColor,
    Color? scaleButtonInactiveBackgroundColor,
    Color? scaleButtonInactiveTextColor,
    Color? loadingIndicatorColor,
  }) {
    const bull = Color(0xFF26A69A);
    const bear = Color(0xFFEF5350);
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);
    const labelBg = Color(0xFF131722);

    return CandleSticksStyle(
      chartBackgroundColor: chartBackgroundColor ?? white,
      gridLineColor: gridLineColor ?? const Color(0xFFF3F3F3),
      axisTextColor: axisTextColor ?? black,
      candleBullColor: candleBullColor ?? bull,
      candleBearColor: candleBearColor ?? bear,
      volumeBullColor: volumeBullColor ?? const Color(0xFF8CCCC6),
      volumeBearColor: volumeBearColor ?? const Color(0xFFF1A3A1),
      crosshairLineColor: crosshairLineColor ?? const Color(0xFF848E9C),
      crosshairLabelBackgroundColor: crosshairLabelBackgroundColor ?? labelBg,
      crosshairLabelTextColor: crosshairLabelTextColor ?? white,
      ohlcInfoTextColor: ohlcInfoTextColor ?? black,
      ohlcInfoBullColor: ohlcInfoBullColor ?? bull,
      ohlcInfoBearColor: ohlcInfoBearColor ?? bear,
      priceIndicatorBullBackgroundColor:
          priceIndicatorBullBackgroundColor ?? bull,
      priceIndicatorBearBackgroundColor:
          priceIndicatorBearBackgroundColor ?? bear,
      priceIndicatorTextColor: priceIndicatorTextColor ?? white,
      scaleButtonActiveBackgroundColor:
          scaleButtonActiveBackgroundColor ?? labelBg,
      scaleButtonActiveTextColor: scaleButtonActiveTextColor ?? white,
      scaleButtonInactiveBackgroundColor:
          scaleButtonInactiveBackgroundColor ?? white,
      scaleButtonInactiveTextColor: scaleButtonInactiveTextColor ?? labelBg,
      loadingIndicatorColor: loadingIndicatorColor ?? const Color(0xFFF0B90A),
    );
  }
}
