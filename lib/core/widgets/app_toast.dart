import 'dart:ui';
import 'package:flutter/material.dart';

/// The semantic type of the toast — controls accent color, icon, and left border.
enum ToastType { success, error, warning, info }

/// A modern glassmorphic toast notification with a semantic left-border accent.
///
/// Usage:
/// ```dart
/// AppToast.show(context, 'Account saved!', type: ToastType.success);
/// AppToast.show(context, 'Something went wrong.', type: ToastType.error);
/// AppToast.show(context, 'Receipt scanning coming soon!', type: ToastType.info);
/// AppToast.show(context, 'Amount must be positive.', type: ToastType.warning);
/// ```
class AppToast {
  AppToast._();

  // ── Config ─────────────────────────────────────────────────────────────────

  static const Duration _defaultDuration = Duration(milliseconds: 3200);

  static _ToastConfig _config(BuildContext context, ToastType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case ToastType.success:
        return _ToastConfig(
          accentColor: isDark ? const Color(0xFF26E09C) : const Color(0xFF15B77E),
          icon: Icons.check_circle_rounded,
          label: 'Success',
        );
      case ToastType.error:
        return _ToastConfig(
          accentColor: isDark ? const Color(0xFFFC8181) : const Color(0xFFE53E3E),
          icon: Icons.error_rounded,
          label: 'Error',
        );
      case ToastType.warning:
        return _ToastConfig(
          accentColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B),
          icon: Icons.warning_rounded,
          label: 'Warning',
        );
      case ToastType.info:
        return _ToastConfig(
          accentColor: isDark ? const Color(0xFF5B9DF9) : const Color(0xFF2F80ED),
          icon: Icons.info_rounded,
          label: 'Info',
        );
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Shows a styled glass toast overlay.
  ///
  /// [message]  — the text to display.
  /// [type]     — semantic type controlling color and icon (default: [ToastType.info]).
  /// [duration] — how long the toast stays visible (default: 3.2 s).
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = _defaultDuration,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final config = _config(context, type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastOverlay(
        message: message,
        config: config,
        isDark: isDark,
        duration: duration,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

// ── Internal helpers ─────────────────────────────────────────────────────────

class _ToastConfig {
  final Color accentColor;
  final IconData icon;
  final String label;

  const _ToastConfig({
    required this.accentColor,
    required this.icon,
    required this.label,
  });
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final _ToastConfig config;
  final bool isDark;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    required this.config,
    required this.isDark,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.config.accentColor;
    final isDark = widget.isDark;

    final glassBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.80);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.65);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.12);
    final textColor =
        isDark ? const Color(0xFFF7FAFC) : const Color(0xFF1A202C);
    final subTextColor =
        isDark ? const Color(0xFFA0AEC0) : const Color(0xFF718096);

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 28),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _dismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 28,
                          spreadRadius: -4,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: accent.withValues(alpha: 0.20),
                          blurRadius: 20,
                          spreadRadius: -6,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: glassBg,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: glassBorder, width: 1.0),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Accent left border ──────────────────
                                Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                ),

                                // ── Icon ────────────────────────────────
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 14,
                                    top: 14,
                                    bottom: 14,
                                    right: 10,
                                  ),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          accent.withValues(alpha: 0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      widget.config.icon,
                                      color: accent,
                                      size: 20,
                                    ),
                                  ),
                                ),

                                // ── Text ────────────────────────────────
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 2,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.config.label,
                                          style: TextStyle(
                                            color: accent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.message,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ── Dismiss button ───────────────────────
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 12,
                                    left: 4,
                                  ),
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: _dismiss,
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: subTextColor
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 13,
                                          color: subTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
