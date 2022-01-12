import 'package:flutter/material.dart';

class DashLine extends StatelessWidget {
  final Axis direction;
  final double thickness;
  final double length;
  final Color color;

  const DashLine({
    Key? key,
    required this.direction,
    required this.thickness,
    required this.length,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isVertical = direction == Axis.vertical;
    return SizedBox(
      height: isVertical ? length : thickness,
      width: isVertical ? thickness : length,
      child: ListView.builder(
          scrollDirection: direction,
          itemCount: length ~/ 2,
          itemBuilder: (context, index) {
            if (index % 2 == 0) {
              return SizedBox(
                  width: isVertical ? null : 2, height: isVertical ? 2 : null);
            }
            return Container(
              width: isVertical ? thickness : 2,
              height: isVertical ? 2 : thickness,
              color: color,
            );
          }),
    );
  }
}
