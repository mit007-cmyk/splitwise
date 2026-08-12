import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/context_extension.dart';

class SimplifyDebtsInfoPage extends StatelessWidget {
  const SimplifyDebtsInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Simplify debts',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── What is simplify debts? ──────────────────────────────────
            Text(
              'What is "simplify debts"?',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Debt simplification (a.k.a. "simplify debts" or "debt shuffling") '
              'is a feature of Splitwise that restructures debt within a group. '
              'It does not change the total amount that anyone owes, but it makes '
              'it easier to pay people back by minimizing the total number of '
              'payments.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.55,
              ),
            ),

            SizedBox(height: 32.h),

            // ── Diagram image ───────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.asset(
                'assets/images/simplify-image.jpg',
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),

            SizedBox(height: 32.h),

            // ── An example ──────────────────────────────────────────────
            Text(
              'An example',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Ana, Bob, and Charlie share an apartment. Bob lends Ana \$10, and '
              'Charlie lends Bob \$10. With "simplify debts" on, Splitwise will '
              'tell Ana to settle up by paying \$10 to Charlie. Bob does nothing. '
              'This ensures the group is all settled up after 1 payment, instead '
              'of 2.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.55,
              ),
            ),

            SizedBox(height: 40.h),

            // ── Info note ────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'This setting is enabled per group and only affects how '
                      'debts are displayed — the underlying expense records '
                      'are never modified.',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

