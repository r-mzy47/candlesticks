import 'package:flutter/material.dart';

class ToolBar extends StatelessWidget {
  const ToolBar({
    Key? key,
    required this.rightChildren,
    required this.leftChildren,
    this.border,
  }) : super(key: key);

  final List<Widget> rightChildren;
  final List<Widget> leftChildren;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: border),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          children: [...leftChildren, Spacer(), ...rightChildren],
        ),
      ),
    );
  }
}
