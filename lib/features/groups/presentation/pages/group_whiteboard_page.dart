import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_event.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';

class GroupWhiteboardPage extends StatefulWidget {
  final String groupId;

  const GroupWhiteboardPage({super.key, required this.groupId});

  @override
  State<GroupWhiteboardPage> createState() => _GroupWhiteboardPageState();
}

class _GroupWhiteboardPageState extends State<GroupWhiteboardPage> {
  late final TextEditingController _controller;
  bool _isLoading = true;
  bool _isSaving = false;
  String _groupName = 'Group';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _fetchWhiteboardData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchWhiteboardData() async {
    try {
      final doc = await getIt<FirestoreService>().getDocument('Splitwise', 'groups');
      final data = doc.data();
      final groupData = data?[widget.groupId] as Map<String, dynamic>?;
      if (groupData != null && mounted) {
        setState(() {
          _groupName = groupData['name'] as String? ?? 'Group';
          _controller.text = groupData['whiteboard'] as String? ?? '';
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Failed to load whiteboard content.', type: ToastType.error);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveWhiteboardData() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final doc = await getIt<FirestoreService>().getDocument('Splitwise', 'groups');
      final data = doc.data() ?? {};
      final groupData = Map<String, dynamic>.from(data[widget.groupId] as Map? ?? {});
      groupData['whiteboard'] = _controller.text;

      await getIt<FirestoreService>().setDocument(
        'Splitwise',
        'groups',
        {
          widget.groupId: groupData,
        },
        merge: true,
      );

      if (mounted) {
        AppToast.show(context, 'Whiteboard saved successfully.', type: ToastType.success);
        // Refresh home state so the updated group details are synchronized locally
        context.read<HomeBloc>().add(const RefreshHome());
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Failed to save whiteboard.', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, homeState) {
        // Resolve group name from home state if loading is still in progress
        if (_groupName == 'Group' && homeState is HomeLoaded) {
          final groupIndex =
              homeState.summary.groups.indexWhere((g) => g.groupId == widget.groupId);
          if (groupIndex != -1) {
            _groupName = homeState.summary.groups[groupIndex].groupName;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Whiteboard'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (!_isLoading)
                TextButton(
                  onPressed: _isSaving ? null : _saveWhiteboardData,
                  child: _isSaving
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          ),
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Group Name Header
                        Text(
                          _groupName,
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Divider(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                        SizedBox(height: 12.h),

                        // Large Board area for typing
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                              ),
                            ),
                            child: TextField(
                              controller: _controller,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: context.textTheme.bodyLarge?.copyWith(
                                height: 1.4,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Write something here...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Explanatory footer text
                        Text(
                          'Use the whiteboard to remember important info, like your landlord\'s address or emergency contact info. The whiteboard is visible to anyone who joins your group.',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
