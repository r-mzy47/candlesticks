## [3.0.1] - May 22, 2026

- [BugFix] Fixed an issue where the hovered date label text could overflow.

## [3.0.0] - May 17, 2026

- [Breaking] Remove the `actions` parameter from `Candlesticks`. Consumers should now provide toolbar/actions UI outside the widget.

- [Feature] add [CandlesticksController] for external chart control
- [Feature] add logarithmic scale support
- [Feature] add custom chart styling with [CandleSticksStyle]
- [Feature] add customizable [loadingWidget]
- [Feature] Add anchored zoom with `Ctrl`/`Command` + scroll. On web, use `Alt`/`Option` + scroll.
- [Feature] add free chart dragging for horizontal scrolling and vertical price adjustment

- [Improvement] simplify [Candlesticks] public API
- [Improvement] move toolbar responsibility outside chart widget
- [Improvement] improve mobile and desktop gesture handling
- [Improvement] improve code structure
- [Improvement] improve performance
- [Improvement] update documentation and examples

## [2.1.0] - Feb 22, 2022

- document correction

## [2.0.0] - Feb 21, 2022

- [Improvement] performance improvement
- [Feature] desktop support
- [Feature] price scaling
- [Feature] add light theme
- [Breaking] interval and onIntervalChange parameters are deleted from [Candlesticks] widget

## [1.1.1] - Sep 10, 2021

- [Improvement] replace [DashLine] widget
 
## [1.1.0] - Sep 9, 2021

- [Improvement] scrolling experience improvement
- [Feature] onHover price and time indicators
 
## [1.0.1] - Jul 28, 2021

- [Feature] add intervals optional parameter

## [1.0.0] - Jul 24, 2021

- [Feature] multi interval
- [Feature] add socket connection to example
- [Feature] add last price indicator
- [BugFix] fix error when srcroll to the left end

## [0.5.0] - Jun 14, 2021

- [Feature] add animated time row
- [Feature] add binance api to example

## [0.4.0] - May 6, 2021

- [Feature] add volume chart
- [Improvement] add scaling high and low price with animation
- [Improvement] performance improvement
- [BugFix] tune price column

## [0.3.0] - May 5, 2021

- [Feature] add interactive price column

## [0.2.4] - Apr 14, 2021

- add documentation

## [0.2.1] - Apr 13, 2021

- [Improvement] scaling animation
- [Feature] add price indicators
- [BugFix] the newest candles are shown first
- [Breaking] candles list order is chanded: newest candle (at index 0) -> older candles

## [0.1.1] - Apr 10, 2021

- [Feature] add animation
- [Feature] add scale gesture

## [0.0.1] - Apr 10, 2021

- initial version