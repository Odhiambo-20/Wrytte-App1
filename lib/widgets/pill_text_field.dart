import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PillTextField extends StatelessWidget {
  const PillTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final String hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
          filled: true,
          fillColor: AppTheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0x334AA3FF),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
