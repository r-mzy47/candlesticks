import 'package:candlesticks/src/theme/color_palette.dart';
import 'package:candlesticks/src/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class ToolBar extends StatelessWidget {
  const ToolBar({
    Key? key,
    required this.onZoomInPressed,
    required this.onZoomOutPressed,
    required this.interval,
    required this.intervals,
    required this.onIntervalChange,
  }) : super(key: key);

  final void Function() onZoomInPressed;
  final void Function() onZoomOutPressed;
  final void Function(String) onIntervalChange;
  final List<String> intervals;
  final String interval;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorPalette.barColor,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          children: [
            CustomButton(
              onPressed: onZoomOutPressed,
              child: Icon(
                Icons.remove,
                color: ColorPalette.grayColor,
              ),
            ),
            CustomButton(
              onPressed: onZoomInPressed,
              child: Icon(
                Icons.add,
                color: ColorPalette.grayColor,
              ),
            ),
            CustomButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Center(
                      child: Container(
                        width: 200,
                        color: ColorPalette.digalogColor,
                        child: Wrap(
                          children: intervals
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CustomButton(
                                    width: 50,
                                    color: ColorPalette.lightGold,
                                    child: Text(
                                      e,
                                      style: TextStyle(
                                        color: ColorPalette.gold,
                                      ),
                                    ),
                                    onPressed: () {
                                      onIntervalChange(e);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Text(
                interval,
                style: TextStyle(
                  color: ColorPalette.grayColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
