import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/domain/services/friend_ledger.dart';
import '../../domain/entities/user_preview.dart';
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

  Widget _buildOverallBalance(BuildContext context, double overallBalance) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;

    if (overallBalance.abs() < 0.01) {
      return RichText(
        text: TextSpan(
          style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
          children: const [
            TextSpan(text: 'You are '),
            TextSpan(text: 'all settled up!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final isOwed = overallBalance > 0;
    return RichText(
      text: TextSpan(
        style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
        children: [
          TextSpan(text: isOwed ? 'Overall, you are owed ' : 'Overall, you owe '),
          TextSpan(
            text: '₹${overallBalance.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOwed ? appColors.positiveBalanceColor : appColors.negativeBalanceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendBalance(BuildContext context, double? balance) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;

    if (balance == null || balance.abs() < 0.01) {
      return Text(
        'settled up',
        style: context.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      );
    }

    final isOwed = balance > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isOwed ? 'owes you' : 'you owe',
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(
          '₹${balance.abs().toStringAsFixed(2)}',
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isOwed ? appColors.positiveBalanceColor : appColors.negativeBalanceColor,
          ),
        ),
      ],
    );
  }

  /// Up to 3 "{friend} owes you ₹x for "{group}"" lines, matching
  /// Splitwise's per-friend breakdown. Beyond that, collapses the tail into
  /// a single "Plus N other balances" line so the tile doesn't grow forever.
  List<String> _breakdownLines(String friendName, List<FriendGroupBalance> breakdown) {
    if (breakdown.isEmpty) return const [];

    String lineFor(FriendGroupBalance b) {
      final amountText = '${b.currencySymbol}${b.amount.abs().toStringAsFixed(2)}';
      return b.amount > 0
          ? '$friendName owes you $amountText for "${b.groupName}"'
          : 'You owe $friendName $amountText for "${b.groupName}"';
    }

    const maxVisible = 3;
    if (breakdown.length <= maxVisible) {
      return breakdown.map(lineFor).toList();
    }

    final remaining = breakdown.length - 2;
    return [
      ...breakdown.take(2).map(lineFor),
      'Plus $remaining other balance${remaining == 1 ? '' : 's'}',
    ];
  }

  Widget _buildFriendTile(
    BuildContext context,
    UserPreview friend,
    double? balance,
    List<FriendGroupBalance> breakdown,
  ) {
    final scheme = context.colorScheme;
    final lines = _breakdownLines(friend.name, breakdown);

    return InkWell(
      onTap: () => _openFriendDetail(friend.id),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.lg.w,
          vertical: AppDimensions.sm.h,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWidget(
              name: friend.name,
              imageUrl: friend.photoUrl,
              size: 44.w,
            ),
            SizedBox(width: AppDimensions.md.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            friend.name,
                            style: context.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      _buildFriendBalance(context, balance),
                    ],
                  ),
                  for (final line in lines)
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 2,
                              color: scheme.outlineVariant.withValues(alpha: 0.6),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                line,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
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
                AppToast.show(context, 'Search coming soon!', type: ToastType.info);
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
          floatingActionButton: AddExpenseExtendedFab(onExpenseAdded: _load),
          body: BlocConsumer<FriendsListCubit, FriendsListState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                AppToast.show(context, state.errorMessage!, type: ToastType.error);
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
                        Expanded(child: _buildOverallBalance(context, state.overallBalance)),
                        IconButton(
                          icon: const Icon(Icons.tune),
                          color: scheme.onSurfaceVariant,
                          onPressed: () {
                          AppToast.show(context, 'Filters coming soon!', type: ToastType.info);
                          },
                        ),
                      ],
                    ),
                  ),
                  ...state.friends.map(
                    (friend) => _buildFriendTile(
                      context,
                      friend,
                      state.balances[friend.id],
                      state.groupBreakdowns[friend.id] ?? const [],
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
