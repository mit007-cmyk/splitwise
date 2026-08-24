import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/routing/route_constants.dart';
import '../../../../core/theme/app_colors.dart';

const List<String> _stepAssets = [
  'assets/videos/first-step.mp4',
  'assets/videos/second-step.mp4',
  'assets/videos/third-step.mp4',
];

class OnboardingTourPage extends StatefulWidget {
  /// Pass true when coming from registration, false from login.
  final bool isNewUser;

  const OnboardingTourPage({super.key, required this.isNewUser});

  @override
  State<OnboardingTourPage> createState() => _OnboardingTourPageState();
}

class _OnboardingTourPageState extends State<OnboardingTourPage>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;

  /// All three controllers are initialized in parallel at startup.
  final List<VideoPlayerController?> _controllers = List.filled(
    _stepAssets.length,
    null,
  );

  bool _firstReady = false; // true once step-0 video is ready to show
  bool _advancing = false; // guard: prevents double-fire from listener

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _preloadAll();
  }

  /// Kick off all three video initializations simultaneously.
  void _preloadAll() {
    for (int i = 0; i < _stepAssets.length; i++) {
      final index = i; // capture for closure
      final controller = VideoPlayerController.asset(_stepAssets[index]);
      _controllers[index] = controller;

      controller.initialize().then((_) {
        if (!mounted) return;

        // Add a listener that auto-advances when this video reaches its end.
        controller.addListener(() {
          if (!mounted) return;
          final val = controller.value;
          // Trigger when the video has played past 98% of its duration
          // (avoids floating-point edge cases at exactly duration).
          if (val.isInitialized &&
              !val.isPlaying &&
              val.position >=
                  val.duration - const Duration(milliseconds: 200) &&
              val.duration > Duration.zero &&
              _currentStep == index) {
            _advance();
          }
        });

        if (index == 0) {
          // Start playing the first video and show UI.
          controller.play();
          setState(() => _firstReady = true);
          _fadeController.forward();
        }
        // For steps 1 and 2: keep paused until navigated there.
      });
    }
  }

  Future<void> _advance() async {
    if (_advancing) return; // prevent double-fire
    _advancing = true;

    if (_currentStep < _stepAssets.length - 1) {
      // Pause current video.
      _controllers[_currentStep]?.pause();

      final next = _currentStep + 1;
      final nextController = _controllers[next];

      setState(() => _currentStep = next);

      // Play next video — it should already be initialized.
      if (nextController != null && nextController.value.isInitialized) {
        await nextController.seekTo(Duration.zero);
        nextController.play();
        _fadeController
          ..reset()
          ..forward();
      }
    } else {
      _finish();
    }

    _advancing = false;
  }

  void _finish() {
    if (widget.isNewUser) {
      context.go(RouteConstants.getStartedPath);
    } else {
      context.go(RouteConstants.homePath);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (final c in _controllers) {
      c?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controllers[_currentStep];
    final videoReady =
        _firstReady && controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Video area (tappable to advance) ───────────────────────
            Expanded(
              child: Stack(
                children: [
                  if (videoReady)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: controller.value.size.width,
                            height: controller.value.size.height,
                            child: VideoPlayer(controller),
                          ),
                        ),
                      ),
                    )
                  else
                    const ColoredBox(
                      color: Color(0xFFF2A882),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  // Overlay to intercept taps
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _advance,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Positioned(
                    bottom: 30.h,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      // color: Colors.white,
                      padding: EdgeInsets.only(top: 20.h, bottom: 20.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Step dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_stepAssets.length, (i) {
                              final active = i == _currentStep;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeInOut,
                                margin: EdgeInsets.symmetric(horizontal: 5.w),
                                width: active ? 24.w : 8.w,
                                height: 8.h,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.primaryLight
                                      : const Color(0xFFBDBDBD),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              );
                            }),
                          ),

                          SizedBox(height: 12.h),

                          // Skip tour
                          TextButton(
                            onPressed: _finish,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryLight,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 4.h,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Skip tour',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
