import 'package:flutter/material.dart';

import 'color_palette.dart';

extension MultiThemeColorExtension on ThemeData {
  // public general color will add below here

  Color get grayColor => brightness == Brightness.light
      ? LightColorPalette.grayColor
      : DarkColorPalette.grayColor;

  Color get background => brightness == Brightness.light
      ? LightColorPalette.background
      : DarkColorPalette.background;

  Color get primaryGreen => brightness == Brightness.light
      ? LightColorPalette.primaryGreen
      : DarkColorPalette.primaryGreen;

  Color get secondaryGreen => brightness == Brightness.light
      ? LightColorPalette.secondaryGreen
      : DarkColorPalette.secondaryGreen;

  Color get primaryRed => brightness == Brightness.light
      ? LightColorPalette.primaryRed
      : DarkColorPalette.primaryRed;

  Color get secondaryRed => brightness == Brightness.light
      ? LightColorPalette.secondaryRed
      : DarkColorPalette.secondaryRed;

  Color get digalogColor => brightness == Brightness.light
      ? LightColorPalette.digalogColor
      : DarkColorPalette.digalogColor;

  Color get lightGold => brightness == Brightness.light
      ? LightColorPalette.lightGold
      : DarkColorPalette.lightGold;

  Color get hoverIndicatorBackgroundColor => brightness == Brightness.light
      ? LightColorPalette.hoverIndicatorBackgroundColor
      : DarkColorPalette.hoverIndicatorBackgroundColor;

  Color get gold => brightness == Brightness.light
      ? LightColorPalette.gold
      : DarkColorPalette.gold;

  Color get hoverIndicatorTextColor => brightness == Brightness.light
      ? LightColorPalette.hoverIndicatorTextColor
      : DarkColorPalette.hoverIndicatorTextColor;

  Color get scaleNumbersColor => brightness == Brightness.light
      ? LightColorPalette.scaleNumbersColor
      : DarkColorPalette.scaleNumbersColor;

  Color get currentPriceColor => brightness == Brightness.light
      ? LightColorPalette.currentPriceColor
      : DarkColorPalette.currentPriceColor;
}
