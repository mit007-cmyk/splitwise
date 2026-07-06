import 'package:flutter/material.dart';
import '../utils/context_extension.dart';
import 'cached_image_widget.dart';
import '../theme/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;

  const AvatarWidget({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40.0,
  });

  /// Computes initials (up to 2 letters) from a given name
  String get _initials {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return '?';

    final parts = cleanName.split(' ');
    if (parts.length > 1) {
      final first = parts[0].substring(0, 1).toUpperCase();
      final second = parts[parts.length - 1].substring(0, 1).toUpperCase();
      return '$first$second';
    }

    return cleanName.substring(0, cleanName.length > 1 ? 2 : 1).toUpperCase();
  }

  /// Generates a deterministic background color based on name hash
  Color _getBackgroundColor(BuildContext context) {
    if (name.isEmpty) return context.colorScheme.primaryContainer;

    final hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    return AppColors.avatarPlaceholders[hash % AppColors.avatarPlaceholders.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: hasImage
          ? CachedImageWidget(
              imageUrl: imageUrl!,
              width: size,
              height: size,
              borderRadius: size / 2,
            )
          : CircleAvatar(
              backgroundColor: _getBackgroundColor(context),
              radius: size / 2,
              child: Text(
                _initials,
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.onImageColor,
                ),
              ),
            ),
    );
  }
}
