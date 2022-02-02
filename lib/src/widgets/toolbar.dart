import 'package:candlesticks/src/theme/theme_data.dart';
import 'package:candlesticks/src/widgets/toolbar_action.dart';
import 'package:flutter/material.dart';

class ToolBar extends StatelessWidget {
  const ToolBar({
    Key? key,
    required this.onZoomInPressed,
    required this.onZoomOutPressed,
    required this.children,
  }) : super(key: key);

  final void Function() onZoomInPressed;
  final void Function() onZoomOutPressed;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).background,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          children: [
            ToolBarAction(
              onPressed: onZoomOutPressed,
              child: Icon(
                Icons.remove,
                color: Theme.of(context).grayColor,
              ),
            ),
            ToolBarAction(
              onPressed: onZoomInPressed,
              child: Icon(
                Icons.add,
                color: Theme.of(context).grayColor,
              ),
            ),
            ...children
          ],
        ),
      ),
    );
  }
}
