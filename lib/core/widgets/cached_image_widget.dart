import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/context_extension.dart';

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0.0,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPlaceholder = Container(
      width: width,
      height: height,
      color: context.colorScheme.surfaceContainerHighest,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );

    final defaultErrorWidget = Container(
      width: width,
      height: height,
      color: context.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported_rounded,
        color: context.colorScheme.onSurfaceVariant,
      ),
    );

    final imageWidget = imageUrl.isEmpty
        ? defaultErrorWidget
        : CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => placeholder ?? defaultPlaceholder,
            errorWidget: (context, url, error) => errorWidget ?? defaultErrorWidget,
          );

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
