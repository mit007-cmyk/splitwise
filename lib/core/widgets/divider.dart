import 'package:flutter/material.dart';
import '../utils/context_extension.dart';

class AppDivider extends StatelessWidget {
  final double thickness;
  final double indent;
  final double endIndent;

  const AppDivider({
    super.key,
    this.thickness = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: thickness,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: context.theme.dividerColor.withOpacity(0.12),
    );
  }
}
