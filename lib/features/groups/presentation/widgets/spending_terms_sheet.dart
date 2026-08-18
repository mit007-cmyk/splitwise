import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';

/// Explains the figures on the group spending screen. Every "?" on that screen
/// opens this same sheet, so the wording covers both terms at once.
class SpendingTermsSheet extends StatelessWidget {
  const SpendingTermsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl.r),
        ),
      ),
      builder: (_) => const SpendingTermsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.xl.w,
            AppDimensions.sm.h,
            AppDimensions.xl.w,
            AppDimensions.xl.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  color: scheme.onSurface,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(height: AppDimensions.sm.h),
              Container(
                width: 56.r,
                height: 56.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary, width: 2.w),
                ),
                child: Icon(
                  Icons.question_mark_rounded,
                  size: 28.r,
                  color: scheme.primary,
                ),
              ),
              SizedBox(height: AppDimensions.xl.h),
              Text(
                'What do these terms mean?',
                style: context.textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(height: AppDimensions.xl.h),
              _buildTerm(
                context,
                term: 'Total spent',
                meaning: 'the total cost of every expense added to the group '
                    'for the time period specified',
              ),
              SizedBox(height: AppDimensions.lg.h),
              _buildTerm(
                context,
                term: 'Your share',
                meaning:
                    'your total share of all group expenses involving you',
              ),
              SizedBox(height: AppDimensions.xxl.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerm(
    BuildContext context, {
    required String term,
    required String meaning,
  }) {
    final base = context.textTheme.bodyLarge?.copyWith(
      color: context.colorScheme.onSurface,
      height: 1.45,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(
            text: term,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' = $meaning'),
        ],
      ),
    );
  }
}
