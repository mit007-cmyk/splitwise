import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/friend_code_info.dart';
import '../widgets/friend_scan_tab.dart';
import '../bloc/my_code_cubit.dart';

class FriendCodePage extends StatefulWidget {
  const FriendCodePage({super.key});

  @override
  State<FriendCodePage> createState() => _FriendCodePageState();
}

class _FriendCodePageState extends State<FriendCodePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MyCodeCubit _myCodeCubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {});
      }
    });
    _myCodeCubit = getIt<MyCodeCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMyCode());
  }

  void _loadMyCode() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _myCodeCubit.load(
        userId: authState.user.id,
        userName: authState.user.name,
        photoUrl: authState.user.photoUrl,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _myCodeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocProvider.value(
      value: _myCodeCubit,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Friend code',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Scan'),
              Tab(text: 'My code'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return TabBarView(
              controller: _tabController,
              children: [
                FriendScanTab(isActive: _tabController.index == 0),
                const _MyCodeTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MyCodeTab extends StatelessWidget {
  const _MyCodeTab();

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      AppToast.show(context, 'Friend code copied', type: ToastType.success);
    }
  }

  Future<void> _shareCode(FriendCodeInfo info) async {
    await Share.share(
      'Add me on Splitwise: ${info.inviteUrl}',
      subject: 'My Splitwise friend code',
    );
  }

  Future<void> _confirmChangeCode(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change friend code?'),
          content: const Text(
            'Your old code will stop working. Anyone who saved it will need your new code.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Change code'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    await context.read<MyCodeCubit>().changeCode(
          userId: authState.user.id,
          userName: authState.user.name,
          photoUrl: authState.user.photoUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;

    return BlocConsumer<MyCodeCubit, MyCodeState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppToast.show(context, state.errorMessage!, type: ToastType.error);
        } else if (state.successMessage != null) {
          AppToast.show(context, state.successMessage!, type: ToastType.success);
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final info = state.info;
        if (info == null) {
          return Center(
            child: Text(
              'Unable to load your friend code.',
              style: context.textTheme.bodyLarge,
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w),
          child: Column(
            children: [
              SizedBox(height: 48.h),
              Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 40.h),
                    padding: EdgeInsets.fromLTRB(
                      AppDimensions.lg.w,
                      56.h,
                      AppDimensions.lg.w,
                      AppDimensions.lg.h,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    ),
                    child: Column(
                      children: [
                        Text(
                          info.userName,
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppDimensions.lg.h),
                        Container(
                          padding: EdgeInsets.all(AppDimensions.md.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          ),
                          child: QrImageView(
                            data: info.inviteUrl,
                            version: QrVersions.auto,
                            size: 200.w,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: AppDimensions.md.h),
                        SelectableText(
                          info.inviteUrl,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: appColors.positiveBalanceColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppDimensions.sm.h),
                        Text(
                          info.code,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: AvatarWidget(
                      name: info.userName,
                      imageUrl: info.photoUrl,
                      size: 80.w,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.lg.h),
              _ActionTile(
                icon: Icons.ios_share_outlined,
                title: 'Share code',
                onTap: () => _shareCode(info),
              ),
              _ActionTile(
                icon: Icons.content_copy_outlined,
                title: 'Copy code',
                onTap: () => _copyCode(context, info.code),
              ),
              _ActionTile(
                icon: Icons.refresh,
                title: 'Change code',
                trailing: state.isChangingCode
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: state.isChangingCode ? null : () => _confirmChangeCode(context),
              ),
              SizedBox(height: AppDimensions.lg.h),
              Text(
                'Only share your code with people you trust. Anyone with your code can add you as a friend.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: AppDimensions.xl.h),
            ],
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: AppDimensions.sm.w),
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(
        title,
        style: context.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ??
          Icon(Icons.chevron_right, color: context.appColors.hintTextColor),
      onTap: onTap,
    );
  }
}
