import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({super.key, required this.onChanged});

  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      cursorColor: const Color(0xFF494537),
      decoration: const InputDecoration(
        prefixIcon: Icon(
          Icons.search,
          color: Color(0xFF494537),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(width: 3, color: Color(0xFF494537)),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 3, color: Color(0xFF494537)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(width: 3, color: Color(0xFF494537)),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
