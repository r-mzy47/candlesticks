import 'package:flutter/material.dart';

class DottedLine extends StatelessWidget {
  /// Creates dotted line with the given parameters
  const DottedLine({
    Key? key,
    this.direction = Axis.horizontal,
    this.lineLength = double.infinity,
    this.lineThickness = 1.0,
    this.dashLength = 4.0,
    this.dashColor = Colors.black,
    this.dashGapLength = 4.0,
    this.dashGapColor = Colors.transparent,
    this.dashRadius = 0.0,
    this.dashGapRadius = 0.0,
  }) : super(key: key);

  /// The direction of the entire dotted line. Default [Axis.horizontal].
  final Axis direction;

  /// The length of the entire dotted line. Default [double.infinity].
  final double lineLength;

  /// The thickness of the entire dotted line. Default (1.0).
  final double lineThickness;

  /// The length of the dash. Default (4.0).
  final double dashLength;

  /// The color of the dash. Default [Colors.black].
  final Color dashColor;

  /// The radius of the dash. Default (0.0).
  final double dashRadius;

  /// The length of the dash gap. Default (4.0).
  final double dashGapLength;

  /// The color of the dash gap. Default [Colors.transparent].
  final Color dashGapColor;

  /// The radius of the dash gap. Default (0.0).
  final double dashGapRadius;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = direction == Axis.horizontal;
    final dash = _buildDash(isHorizontal);
    final dashGap = _buildDashGap(isHorizontal);

    return SizedBox(
      width: isHorizontal ? lineLength : lineThickness,
      height: isHorizontal ? lineThickness : lineLength,
      child: LayoutBuilder(builder: (context, constraints) {
        final lineLength = _getLineLength(constraints, isHorizontal);
        final dashAndDashGapCount = _calculateDashAndDashGapCount(lineLength);

        return Wrap(
          direction: direction,
          children: List.generate(dashAndDashGapCount, (index) {
            return index % 2 == 0 ? dash : dashGap;
          }).toList(growable: false),
        );
      }),
    );
  }

  /// If [lineLength] is [double.infinity],
  /// get the maximum value of the parent widget.
  /// And if the value is specified, use the specified value.
  double _getLineLength(BoxConstraints constraints, bool isHorizontal) {
    return lineLength == double.infinity
        ? isHorizontal
            ? constraints.maxWidth
            : constraints.maxHeight
        : lineLength;
  }

  /// Calculate the count of (dash + dashGap).
  ///
  /// example1) [lineLength] is 10, [dashLength] is 1, [dashGapLength] is 1.
  /// "- - - - - "
  /// example2) [lineLength] is 10, [dashLength] is 1, [dashGapLength] is 2.
  /// "-  -  -  -"
  int _calculateDashAndDashGapCount(double lineLength) {
    final dashAndDashGapLength = dashLength + dashGapLength;
    var dashAndDashGapCount = lineLength / dashAndDashGapLength * 2;

    if (dashLength <= lineLength % dashAndDashGapLength) {
      dashAndDashGapCount += 1;
    }

    return dashAndDashGapCount.toInt();
  }

  Widget _buildDash(bool isHorizontal) {
    return Container(
      decoration: BoxDecoration(
        color: dashColor,
        borderRadius: BorderRadius.circular(dashRadius),
      ),
      width: isHorizontal ? dashLength : lineThickness,
      height: isHorizontal ? lineThickness : dashLength,
    );
  }

  Widget _buildDashGap(bool isHorizontal) {
    return Container(
      decoration: BoxDecoration(
        color: dashGapColor,
        borderRadius: BorderRadius.circular(dashGapRadius),
      ),
      width: isHorizontal ? dashGapLength : lineThickness,
      height: isHorizontal ? lineThickness : dashGapLength,
    );
  }
}