import 'dart:ui';

class CandleSticksStyle {
  final Color borderColor;

  final Color background;

  final Color primaryBull;

  final Color secondaryBull;

  final Color primaryBear;

  final Color secondaryBear;

  final Color hoverIndicatorBackgroundColor;

  final Color mobileCandleHoverColor;

  final Color primaryTextColor;

  final Color secondaryTextColor;

  final Color loadingColor;

  final Color toolBarColor;

  CandleSticksStyle({
    required this.borderColor,
    required this.background,
    required this.primaryBull,
    required this.secondaryBull,
    required this.primaryBear,
    required this.secondaryBear,
    required this.hoverIndicatorBackgroundColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.mobileCandleHoverColor,
    required this.loadingColor,
    required this.toolBarColor,
  });

  factory CandleSticksStyle.dark({
    Color? borderColor,
    Color? background,
    Color? primaryBull,
    Color? secondaryBull,
    Color? primaryBear,
    Color? secondaryBear,
    Color? hoverIndicatorBackgroundColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? mobileCandleHoverColor,
    Color? loadingColor,
    Color? toolBarColor,
  }) {
    return CandleSticksStyle(
      borderColor: borderColor ?? Color(0xFF848E9C),
      background: background ?? Color(0xFF191B20),
      primaryBull: primaryBull ?? Color(0xFF26A69A),
      secondaryBull: secondaryBull ?? Color(0xFF005940),
      primaryBear: primaryBear ?? Color(0xFFEF5350),
      secondaryBear: secondaryBear ?? Color(0xFF82122B),
      hoverIndicatorBackgroundColor:
          hoverIndicatorBackgroundColor ?? Color(0xFF4C525E),
      primaryTextColor: primaryTextColor ?? Color(0xFF848E9C),
      secondaryTextColor: secondaryTextColor ?? Color(0XFFFFFFFF),
      mobileCandleHoverColor:
          mobileCandleHoverColor ?? Color(0xFFF0B90A).withOpacity(0.2),
      loadingColor: loadingColor ?? Color(0xFFF0B90A),
      toolBarColor: toolBarColor ?? Color(0xFF191B20),
    );
  }

  factory CandleSticksStyle.light({
    Color? borderColor,
    Color? background,
    Color? primaryBull,
    Color? secondaryBull,
    Color? primaryBear,
    Color? secondaryBear,
    Color? hoverIndicatorBackgroundColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? mobileCandleHoverColor,
    Color? loadingColor,
    Color? toolBarColor,
  }) {
    return CandleSticksStyle(
      borderColor: borderColor ?? Color(0xFF848E9C),
      background: background ?? Color(0xFFFAFAFA),
      primaryBull: primaryBull ?? Color(0xFF026A69A),
      secondaryBull: secondaryBull ?? Color(0xFF8CCCC6),
      primaryBear: primaryBear ?? Color(0xFFEF5350),
      secondaryBear: secondaryBear ?? Color(0xFFF1A3A1),
      hoverIndicatorBackgroundColor:
          hoverIndicatorBackgroundColor ?? Color(0xFF131722),
      primaryTextColor: primaryTextColor ?? Color(0XFF000000),
      secondaryTextColor: secondaryTextColor ?? Color(0XFFFFFFFF),
      mobileCandleHoverColor:
          mobileCandleHoverColor ?? Color(0xFFF0B90A).withOpacity(0.2),
      loadingColor: loadingColor ?? Color(0xFFF0B90A),
      toolBarColor: toolBarColor ?? Color(0xFFFAFAFA),
    );
  }
}
