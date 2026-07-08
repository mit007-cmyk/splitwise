import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../domain/entities/user_preview.dart';

String friendFirstName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return 'them';
  return trimmed.split(RegExp(r'\s+')).first;
}

/// Splitwise-style confirmation dialog after scanning a friend code.
class AddFriendConfirmDialog extends StatefulWidget {
  final UserPreview user;

  const AddFriendConfirmDialog({
    super.key,
    required this.user,
  });

  @override
  State<AddFriendConfirmDialog> createState() => _AddFriendConfirmDialogState();
}

class _AddFriendConfirmDialogState extends State<AddFriendConfirmDialog> {
  bool _isAdding = false;

  void _confirm() {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    Navigator.of(context).pop(true);
  }

  void _dismiss() {
    if (_isAdding) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final firstName = friendFirstName(widget.user.name);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: AppDimensions.xl.w),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 44.h),
            padding: EdgeInsets.fromLTRB(
              AppDimensions.xl.w,
              56.h,
              AppDimensions.xl.w,
              AppDimensions.xl.h,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.user.name,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: AppDimensions.md.h),
                Text(
                  'Do you want to add $firstName as a friend on Splitwise?',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: AppDimensions.xl.h),
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight.h,
                  child: FilledButton(
                    onPressed: _isAdding ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                    child: _isAdding
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : Text(
                            'Yes, add now',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimary,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: AppDimensions.md.h),
                TextButton(
                  onPressed: _isAdding ? null : _dismiss,
                  child: Text(
                    'Dismiss',
                    style: context.textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: AvatarWidget(
              name: widget.user.name,
              imageUrl: widget.user.photoUrl,
              size: 88.w,
            ),
          ),
        ],
      ),
    );
  }
}
