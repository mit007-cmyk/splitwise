import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/friends_list_cubit.dart';
import '../widgets/add_expense_extended_fab.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late final FriendsListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<FriendsListCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _cubit.load(authState.user.id);
    } else {
      _cubit.setIdle();
    }
  }

  Future<void> _openAddFriend() async {
    await context.pushNamed(RouteConstants.addFriendSearchName);
    if (mounted) {
      _load();
    }
  }

  Future<void> _openFriendDetail(String friendId) async {
    await context.pushNamed(
      RouteConstants.friendDetailName,
      pathParameters: {'friendId': friendId},
    );
    if (mounted) {
      _load();
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType,
        listener: (context, authState) {
          if (authState is Authenticated) {
            _cubit.load(authState.user.id);
          } else {
            _cubit.setIdle();
          }
        },
        child: Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            title: const SizedBox.shrink(),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search coming soon!')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                tooltip: 'Add friend',
                onPressed: _openAddFriend,
              ),
              SizedBox(width: AppDimensions.sm.w),
            ],
          ),
          floatingActionButton: const AddExpenseExtendedFab(),
          body: BlocConsumer<FriendsListCubit, FriendsListState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!)),
                );
              }
            },
            builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.friends.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async => _load(),
                child: ListView(
                  children: [
                    SizedBox(height: 120.h),
                    Icon(
                      Icons.people_outline,
                      size: 56.sp,
                      color: scheme.onSurfaceVariant,
                    ),
                    SizedBox(height: AppDimensions.md.h),
                    Text(
                      'No friends yet',
                      textAlign: TextAlign.center,
                      style: context.textTheme.titleMedium,
                    ),
                    SizedBox(height: AppDimensions.sm.h),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.xl.w,
                      ),
                      child: Text(
                        'Scan a friend\'s QR code or share your code to connect.',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(height: AppDimensions.xl.h),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.xl.w,
                      ),
                      child: OutlinedButton.icon(
                        onPressed: _openAddFriend,
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Add more friends'),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _load(),
              child: ListView(
                padding: EdgeInsets.only(bottom: 88.h),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppDimensions.lg.w,
                      AppDimensions.sm.h,
                      AppDimensions.lg.w,
                      AppDimensions.md.h,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: context.textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurface,
                              ),
                              children: const [
                                TextSpan(text: 'You are '),
                                TextSpan(
                                  text: 'all settled up!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune),
                          color: scheme.onSurfaceVariant,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Filters coming soon!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  ...state.friends.map(
                    (friend) => ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.lg.w,
                      ),
                      leading: AvatarWidget(
                        name: friend.name,
                        imageUrl: friend.photoUrl,
                        size: 44.w,
                      ),
                      title: Text(
                        friend.name,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        'no expenses',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      onTap: () => _openFriendDetail(friend.id),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppDimensions.lg.w,
                      AppDimensions.md.h,
                      AppDimensions.lg.w,
                      AppDimensions.lg.h,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: _openAddFriend,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: scheme.primary),
                        foregroundColor: scheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Add more friends'),
                    ),
                  ),
                ],
              ),
            );
            },
          ),
        ),
      ),
    );
  }
}
