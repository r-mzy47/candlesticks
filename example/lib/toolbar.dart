import 'package:flutter/material.dart';

class ToolBar extends StatelessWidget {
  const ToolBar({
    Key? key,
    required this.children,
    this.border,
  }) : super(key: key);

  final List<Widget> children;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: border),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          children: children,
        ),
      ),
    );
  }
}
