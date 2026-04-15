import 'package:flutter/material.dart';

class ToolBar extends StatelessWidget {
  const ToolBar({
    Key? key,
    required this.children,
    required this.color,
    this.border,
  }) : super(key: key);

  final List<Widget> children;
  final Color color;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: border, color: color),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          children: children,
        ),
      ),
    );
  }
}
