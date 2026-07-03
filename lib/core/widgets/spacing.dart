import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class Spacing extends StatelessWidget {
  final double? width;
  final double? height;

  const Spacing({super.key, this.width, this.height});

  const Spacing.horizontal(double size, {Key? key}) : this(width: size, key: key);
  const Spacing.vertical(double size, {Key? key}) : this(height: size, key: key);

  // Ready-made constants mapping to tokens
  static const Widget xs = Spacing(width: AppDimensions.xs, height: AppDimensions.xs);
  static const Widget sm = Spacing(width: AppDimensions.sm, height: AppDimensions.sm);
  static const Widget md = Spacing(width: AppDimensions.md, height: AppDimensions.md);
  static const Widget lg = Spacing(width: AppDimensions.lg, height: AppDimensions.lg);
  static const Widget xl = Spacing(width: AppDimensions.xl, height: AppDimensions.xl);
  static const Widget xxl = Spacing(width: AppDimensions.xxl, height: AppDimensions.xxl);

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height);
  }
}
