import 'package:candlesticks/src/theme/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:candlesticks/src/constant/scales.dart';

class PriceColumn extends StatelessWidget {
  const PriceColumn({
    Key? key,
    required this.tileHeight,
    required this.high,
    required this.scaleIndex,
    required this.width,
    required this.height,
  }) : super(key: key);

  final double tileHeight;
  final double high;
  final int scaleIndex;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 400),
      top: 20 - tileHeight / 2,
      child: Container(
        height: height,
        width: width,
        child: ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          itemCount: 100,
          itemBuilder: (context, index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 400),
              height: tileHeight,
              child: Center(
                child: Row(
                  children: [
                    Container(
                      width: width - 50,
                      height: 0.3,
                      color: ColorPalette.grayColor,
                    ),
                    Text(
                      "-${(high - scales[scaleIndex] * index).toInt()}",
                      style: TextStyle(
                        color: ColorPalette.grayColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
