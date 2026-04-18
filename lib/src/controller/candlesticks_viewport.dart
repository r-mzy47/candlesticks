class CandlesticksViewport {
  final int scrollIndex;
  final double candleWidth;

  const CandlesticksViewport({
    required this.scrollIndex,
    required this.candleWidth,
  });

  CandlesticksViewport copyWith({
    int? scrollIndex,
    double? candleWidth,
  }) {
    return CandlesticksViewport(
      scrollIndex: scrollIndex ?? this.scrollIndex,
      candleWidth: candleWidth ?? this.candleWidth,
    );
  }
}
