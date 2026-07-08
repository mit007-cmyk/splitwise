import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:splitwise/core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/repositories/friends_repository.dart';
import '../bloc/add_friend_cubit.dart';

class AddFriendPage extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;
  final String? initialEmail;

  const AddFriendPage({
    super.key,
    this.initialName,
    this.initialPhone,
    this.initialEmail,
  });

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _currentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.id;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocProvider<AddFriendCubit>(
      create: (context) => AddFriendCubit(
        friendsRepository: getIt<FriendsRepository>(),
        initialName: widget.initialName,
        initialPhone: widget.initialPhone,
        initialEmail: widget.initialEmail,
      ),
      child: BlocConsumer<AddFriendCubit, AddFriendState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Friend added successfully!')),
            );
            context.pop();
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<AddFriendCubit>();
          final isValid = state.isValid;
          final currentUserId = _currentUserId();

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Add friend',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.check,
                    color: isValid
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                  ),
                  onPressed: isValid && !state.isLoading
                      ? () {
                          final uid = currentUserId;
                          if (uid == null) return;
                          cubit.addFriend(currentUserId: uid);
                        }
                      : null,
                ),
              ],
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 16.h,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _nameController,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    labelStyle: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    alignLabelWithHint: true,
                                  ),
                                  onChanged: cubit.updateName,
                                ),
                                SizedBox(height: 24.h),
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Phone number',
                                    labelStyle: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    alignLabelWithHint: true,
                                  ),
                                  onChanged: cubit.updatePhone,
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 16.w),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Email address',
                                    labelStyle: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    alignLabelWithHint: true,
                                  ),
                                  onChanged: cubit.updateEmail,
                                ),
                                SizedBox(height: 24.h),
                                Text(
                                  "Don't worry, nothing sends just yet. You will have another chance to review before sending.",
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isValid
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.08),
                                foregroundColor: isValid
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              onPressed: isValid && !state.isLoading
                                  ? () {
                                      final uid = currentUserId;
                                      if (uid == null) return;
                                      cubit.addFriend(currentUserId: uid);
                                    }
                                  : null,
                              child: Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
