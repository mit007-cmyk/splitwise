import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/utils/friend_code_parser.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../utils/add_friend_flow.dart';

/// QR scanner tab. [isActive] should be true only when this tab is visible so the
/// camera is paused while on "My code".
class FriendScanTab extends StatefulWidget {
  final bool isActive;

  const FriendScanTab({
    super.key,
    this.isActive = true,
  });

  @override
  State<FriendScanTab> createState() => _FriendScanTabState();
}

class _FriendScanTabState extends State<FriendScanTab>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final TextEditingController _manualCodeController = TextEditingController();
  bool _hasHandledScan = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isActive) {
        _scannerController.start();
      }
    });
  }

  @override
  void didUpdateWidget(FriendScanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCameraWithTabVisibility();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (widget.isActive) {
          _scannerController.start();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _scannerController.stop();
    }
  }

  void _syncCameraWithTabVisibility() {
    if (!mounted) return;
    if (widget.isActive) {
      _scannerController.start();
    } else {
      _scannerController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _openInvite(String rawValue) {
    final code = FriendCodeParser.parse(rawValue);
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid friend code')),
      );
      return;
    }

    _scannerController.stop();

    AddFriendFlow.handleCode(context, code).then((_) {
      if (!mounted) return;
      setState(() => _hasHandledScan = false);
      if (widget.isActive) {
        _scannerController.start();
      }
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasHandledScan || !widget.isActive) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;

      final code = FriendCodeParser.parse(value);
      if (code == null) continue;

      setState(() => _hasHandledScan = true);
      _openInvite(code);
      return;
    }
  }

  void _submitManualCode() {
    _openInvite(_manualCodeController.text);
  }

  String _errorMessage(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Camera permission is required to scan QR codes. Enable it in app settings.',
      MobileScannerErrorCode.unsupported =>
        'This device does not support QR scanning.',
      MobileScannerErrorCode.controllerDisposed =>
        'Scanner was closed. Reopen this screen to try again.',
      _ => 'Camera unavailable. Enter a code below.',
    };
  }

  Widget _buildScannerArea(BuildContext context, bool isAuthenticated) {
    final scheme = context.colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: MobileScanner(
            controller: _scannerController,
            fit: BoxFit.cover,
            onDetect: isAuthenticated && widget.isActive ? _onDetect : null,
            placeholderBuilder: (context, child) {
              return ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(height: AppDimensions.md.h),
                      Text(
                        'Starting camera…',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            errorBuilder: (context, error, child) {
              return _ScannerUnavailablePanel(
                scheme: scheme,
                message: _errorMessage(error),
              );
            },
          ),
        ),
        Positioned(
          left: AppDimensions.lg.w,
          right: AppDimensions.lg.w,
          bottom: AppDimensions.lg.h,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.md.w,
              vertical: AppDimensions.sm.h,
            ),
            decoration: BoxDecoration(
              color: scheme.scrim.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Text(
              'Point your camera at a friend\'s QR code',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onInverseSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final authState = context.watch<AuthBloc>().state;
    final isAuthenticated = authState is Authenticated;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.lg.w),
            child: _buildScannerArea(context, isAuthenticated),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.lg.w,
            0,
            AppDimensions.lg.w,
            AppDimensions.lg.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Or enter a code manually',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppDimensions.sm.h),
              TextField(
                controller: _manualCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'SPLT-XXXXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.md.h),
              FilledButton(
                onPressed: isAuthenticated ? _submitManualCode : null,
                child: const Text('Look up code'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScannerUnavailablePanel extends StatelessWidget {
  final ColorScheme scheme;
  final String? message;

  const _ScannerUnavailablePanel({
    required this.scheme,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppDimensions.xl.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 56.sp,
            color: scheme.onSurfaceVariant,
          ),
          SizedBox(height: AppDimensions.md.h),
          Text(
            message ?? 'Camera scanner unavailable',
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppDimensions.sm.h),
          Text(
            'You can still add friends by entering their code below. '
            'If this persists, fully stop the app and run again (not hot reload).',
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
