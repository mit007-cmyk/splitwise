import 'package:flutter/material.dart';
import '../utils/context_extension.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? context.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class AppLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const AppLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) ...[
          const ModalBarrier(
            dismissible: false,
            color: Colors.black45,
          ),
          Center(
            child: Card(
              color: context.colorScheme.surface,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: AppLoadingIndicator(size: 36),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
