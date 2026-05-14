import 'package:flutter/material.dart';

/// Top toolbar button widget.
class ToolBarAction extends StatelessWidget {
  final void Function() onPressed;
  final Widget child;
  final double width;
  final Color? color;

  const ToolBarAction({
    super.key,
    required this.child,
    required this.onPressed,
    this.width = 30,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 30,
      child: RawMaterialButton(
        elevation: 0,
        fillColor: color,
        onPressed: onPressed,
        child: Center(child: child),
      ),
    );
  }
}
