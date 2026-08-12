import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_constants.dart';
import '../../../../core/theme/app_colors.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  void _goHome(BuildContext context) => context.go(RouteConstants.homePath);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F2),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 32.h),

              // ── Party-popper icon ────────────────────────────────────
              const Text(
                '🎉',
                style: TextStyle(fontSize: 40),
              ),

              SizedBox(height: 28.h),

              // ── Heading ──────────────────────────────────────────────
              Text(
                "Let's get started",
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2E2A),
                  height: 1.2,
                ),
              ),

              SizedBox(height: 12.h),

              // ── Subtitle ─────────────────────────────────────────────
              Text(
                'What would you like to do first?',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF4A6660),
                  height: 1.4,
                ),
              ),

              // ── Spacer pushes buttons to bottom ──────────────────────
              const Spacer(),

              // ── Action buttons ───────────────────────────────────────
              _ActionButton(
                emoji: '✈️',
                label: 'Add a group trip',
                onTap: () => _goHome(context),
              ),

              SizedBox(height: 12.h),

              _ActionButton(
                emoji: '🏠',
                label: 'Add your household',
                onTap: () => _goHome(context),
              ),

              SizedBox(height: 20.h),

              // ── Skip link ─────────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () => _goHome(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                  ),
                  child: Text(
                    'Skip setup for now',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A7A5E),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            SizedBox(width: 10.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
