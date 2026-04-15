import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WrytteLogo extends StatelessWidget {
  const WrytteLogo({super.key, this.size = 100});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          'W',
          style: TextStyle(
            fontSize: size * 0.7,
            fontWeight: FontWeight.w700,
            color: AppTheme.accent,
          ),
        ),
      ),
    );
  }
}
