import 'package:flutter/material.dart';
import '../utils/context_extension.dart';
import 'cached_image_widget.dart';
import 'geometric_identicon.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final double? borderWidth;

  const AvatarWidget({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40.0,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final stroke = borderWidth ?? 4.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: stroke > 0
            ? Border.all(color: colorScheme.surface, width: stroke)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? CachedImageWidget(
              imageUrl: imageUrl!,
              width: size,
              height: size,
              borderRadius: size / 2,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final side = constraints.biggest.shortestSide;
                return GeometricIdenticon(
                  seed: name,
                  size: side.isFinite && side > 0 ? side : size,
                );
              },
            ),
    );
  }
}
