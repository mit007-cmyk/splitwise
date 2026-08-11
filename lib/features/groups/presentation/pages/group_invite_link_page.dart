import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/di/di.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_event.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';

class GroupInviteLinkPage extends StatefulWidget {
  final String groupId;

  const GroupInviteLinkPage({super.key, required this.groupId});

  @override
  State<GroupInviteLinkPage> createState() => _GroupInviteLinkPageState();
}

class _GroupInviteLinkPageState extends State<GroupInviteLinkPage> {
  bool _isLoading = true;
  String _groupName = 'Group';
  String _inviteCode = '';

  @override
  void initState() {
    super.initState();
    _fetchOrCreateInviteLink();
  }

  String _generateCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+';
    final rand = math.Random();
    // Generates a 16-character code containing alphanumeric and '+' chars
    return List.generate(16, (i) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _fetchOrCreateInviteLink() async {
    try {
      final doc = await getIt<FirestoreService>().getDocument('Splitwise', 'groups');
      final data = doc.data();
      final groupData = data?[widget.groupId] as Map<String, dynamic>?;

      if (groupData != null) {
        final existingCode = groupData['inviteCode'] as String? ?? '';
        if (existingCode.isNotEmpty) {
          if (mounted) {
            setState(() {
              _groupName = groupData['name'] as String? ?? 'Group';
              _inviteCode = existingCode;
              _isLoading = false;
            });
          }
        } else {
          // If no code exists, generate one and save it
          final newCode = _generateCode();
          final updatedGroup = Map<String, dynamic>.from(groupData);
          updatedGroup['inviteCode'] = newCode;

          await getIt<FirestoreService>().setDocument(
            'Splitwise',
            'groups',
            {
              widget.groupId: updatedGroup,
            },
            merge: true,
          );

          if (mounted) {
            setState(() {
              _groupName = groupData['name'] as String? ?? 'Group';
              _inviteCode = newCode;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Failed to retrieve invite link details.', type: ToastType.error);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _regenerateInviteLink() async {
    try {
      final doc = await getIt<FirestoreService>().getDocument('Splitwise', 'groups');
      final data = doc.data() ?? {};
      final groupData = Map<String, dynamic>.from(data[widget.groupId] as Map? ?? {});

      final newCode = _generateCode();
      groupData['inviteCode'] = newCode;

      await getIt<FirestoreService>().setDocument(
        'Splitwise',
        'groups',
        {
          widget.groupId: groupData,
        },
        merge: true,
      );

      if (mounted) {
        setState(() {
          _inviteCode = newCode;
        });
        // Sync home state local storage
        context.read<HomeBloc>().add(const RefreshHome());
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Failed to update invite link.', type: ToastType.error);
      }
    }
  }

  void _showChangeConfirmationDialog() {
    final theme = context.theme;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            'Change link?',
            style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _regenerateInviteLink();
                if (mounted) {
                  _showSuccessDialog();
                }
              },
              child: Text(
                'Change link',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    final theme = context.theme;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          content: Text(
            'The previous invite link has been invalidated and a new invite link has been generated.',
            style: context.textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String get _inviteUrl => 'https://www.splitwise.com/join/$_inviteCode?v=s';

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _inviteUrl));
    AppToast.show(context, 'Link copied to clipboard!', type: ToastType.success);
  }

  void _shareInviteLink() {
    Share.share('Join my Splitwise group "$_groupName" by clicking here: $_inviteUrl');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, homeState) {
        if (_groupName == 'Group' && homeState is HomeLoaded) {
          final groupIndex =
              homeState.summary.groups.indexWhere((g) => g.groupId == widget.groupId);
          if (groupIndex != -1) {
            _groupName = homeState.summary.groups[groupIndex].groupName;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Invite link'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Description Header text
                        Text(
                          'Anyone can follow this link to join "$_groupName". Only share it with people you trust.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.9),
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: 32.h),

                        // Invite URL Card Row containing the circular link icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 56.w,
                              height: 56.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2FB285), // Green shade matching Splitwise UI theme
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.link_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Text(
                                _inviteUrl,
                                style: context.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32.h),
                        Divider(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                          height: 1,
                        ),
                        SizedBox(height: 16.h),

                        // 1. Copy link list item
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.copy_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 24.r,
                          ),
                          title: Text(
                            'Copy link',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: _copyToClipboard,
                        ),
                        SizedBox(height: 8.h),

                        // 2. Share link list item
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.share_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 24.r,
                          ),
                          title: Text(
                            'Share link',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: _shareInviteLink,
                        ),
                        SizedBox(height: 8.h),

                        // 3. Change link list item
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.remove_circle_outline_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 24.r,
                          ),
                          title: Text(
                            'Change link',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: _showChangeConfirmationDialog,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
