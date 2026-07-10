import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/domain/services/friend_ledger.dart';
import '../../domain/entities/user_preview.dart';
import '../bloc/friend_detail_cubit.dart';
import '../../../../core/widgets/app_toast.dart';
import '../widgets/add_expense_extended_fab.dart';
import '../widgets/friend_action_pill.dart';
import '../widgets/friend_expenses_empty_state.dart';

class FriendDetailPage extends StatefulWidget {
  final String friendId;

  const FriendDetailPage({super.key, required this.friendId});

  @override
  State<FriendDetailPage> createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends State<FriendDetailPage> {
  late final FriendDetailCubit _cubit;
  bool _breakdownExpanded = true;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<FriendDetailCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _cubit.load(currentUserId: authState.user.id, friendId: widget.friendId);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Color _heroColor(String name) {
    return AppColors.avatarPlaceholders[name.length %
        AppColors.avatarPlaceholders.length];
  }

  Color _heroColorDark(String name) {
    return Color.lerp(_heroColor(name), AppColors.shadow, 0.35)!;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<FriendDetailCubit, FriendDetailState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: scheme.surface,
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null
                ? Center(child: Text(state.errorMessage!))
                : _buildBody(context, state, state.friend!),
            floatingActionButton: state.friend == null
                ? null
                : AddExpenseExtendedFab(
                    friendId: widget.friendId,
                    onExpenseAdded: _load,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FriendDetailState state,
    UserPreview friend,
  ) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;
    final heroColor = _heroColor(friend.name);
    final heroColorDark = _heroColorDark(friend.name);
    final balance = state.totalBalance;

    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  height: 170.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [heroColor, heroColorDark],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: appColors.onImageColor,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: appColors.overlayColor
                                  .withValues(alpha: 0.3),
                              shape: const CircleBorder(),
                            ),
                            onPressed: () => context.pop(),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.settings_outlined,
                              color: appColors.onImageColor,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: appColors.overlayColor
                                  .withValues(alpha: 0.3),
                              shape: const CircleBorder(),
                            ),
                            onPressed: () async {
                              await context.pushNamed(
                                RouteConstants.friendSettingsName,
                                pathParameters: {'friendId': widget.friendId},
                              );
                              if (mounted) {
                                _load();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 130.h,
                  left: AppDimensions.xxl.w,
                  child: AvatarWidget(
                    name: friend.name,
                    imageUrl: friend.photoUrl,
                    size: 88.w,
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.xxl.w,
                52.h,
                AppDimensions.lg.w,
                0,
              ),
              child: Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        VerticalDivider(
                          color: heroColor,
                          thickness: 3.w,
                          width: 3.w,
                        ),
                        SizedBox(width: AppDimensions.md.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                friend.name,
                                style: context.textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onSurface,
                                    ),
                              ),
                              SizedBox(height: AppDimensions.sm.h),
                              _buildBalanceBreakdown(
                                context,
                                state,
                                friend.name,
                                balance,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppDimensions.lg.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FriendActionPill(
                          label: 'Settle up',
                          onTap: () {
                            final authState =
                                context.read<AuthBloc>().state;
                            if (authState is! Authenticated) return;
                            context.pushNamed(
                              RouteConstants.friendRecordPaymentName,
                              pathParameters: {'friendId': friend.id},
                              queryParameters: {
                                'currentUserId': authState.user.id,
                                'friendName': friend.name,
                                if (friend.email != null)
                                  'friendEmail': friend.email!,
                                if (friend.photoUrl != null)
                                  'friendPhotoUrl': friend.photoUrl!,
                                'balance': balance.toStringAsFixed(2),
                                if (state.soleSharedGroupId != null)
                                  'groupId': state.soleSharedGroupId!,
                              },
                            );
                          },
                        ),
                        FriendActionPill(
                          label: 'Remind...',
                          onTap: () => _showComingSoon(context),
                        ),
                        FriendActionPill(
                          label: 'Charts',
                          icon: Icons.diamond_rounded,
                          onTap: () => _showComingSoon(context),
                        ),
                        FriendActionPill(
                          label: 'Balances',
                          onTap: () => _showComingSoon(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.entries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: FriendExpensesEmptyState(),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(top: AppDimensions.lg.h, bottom: 96.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _buildActivityFeed(context, state),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Header balance line (with an expand/collapse chevron alongside it when
  /// there's a breakdown to show) plus, when expanded, one left-aligned
  /// "{friend} owes you ₹x in "{group}"" line per shared group — matching
  /// Splitwise's balance summary block on the friend detail screen.
  Widget _buildBalanceBreakdown(
    BuildContext context,
    FriendDetailState state,
    String friendName,
    double balance,
  ) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;
    final breakdown = state.groupBalances;
    final isSettled = balance.abs() < 0.01;
    final isOwed = balance > 0;
    final balanceColor = isSettled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.75)
        : isOwed
        ? appColors.positiveBalanceColor
        : appColors.negativeBalanceColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isSettled
                    ? 'You are all settled up.'
                    : isOwed
                    ? 'You are owed ₹${balance.abs().toStringAsFixed(2)} overall'
                    : 'You owe ₹${balance.abs().toStringAsFixed(2)} overall',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: balanceColor,
                ),
              ),
            ),
            if (breakdown.isNotEmpty)
              InkWell(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusCircular,
                ),
                onTap: () =>
                    setState(() => _breakdownExpanded = !_breakdownExpanded),
                child: Padding(
                  padding: EdgeInsets.all(4.r),
                  child: Icon(
                    _breakdownExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20.r,
                    color: balanceColor,
                  ),
                ),
              ),
          ],
        ),
        if (_breakdownExpanded && breakdown.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: AppDimensions.sm.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in breakdown)
                  Padding(
                    padding: EdgeInsets.only(bottom: AppDimensions.sm.h),
                    child: Text(
                      group.amount > 0
                          ? '$friendName owes you ${group.currencySymbol}${group.amount.abs().toStringAsFixed(2)} in "${group.groupName}"'
                          : 'You owe $friendName ${group.currencySymbol}${group.amount.abs().toStringAsFixed(2)} in "${group.groupName}"',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// One row per shared group, most recent activity first, with a month
  /// divider inserted whenever the activity crosses into an earlier month —
  /// mirrors Splitwise's friend activity feed.
  List<Widget> _buildActivityFeed(
    BuildContext context,
    FriendDetailState state,
  ) {
    final feed = [...state.groupBalances]
      ..sort((a, b) => b.lastActivityDate.compareTo(a.lastActivityDate));

    final widgets = <Widget>[];
    int? lastMonthKey;
    for (final group in feed) {
      final monthKey =
          group.lastActivityDate.year * 12 + group.lastActivityDate.month;
      if (lastMonthKey != null && monthKey != lastMonthKey) {
        widgets.add(_buildMonthHeader(context, group.lastActivityDate));
      }
      widgets.add(_buildGroupActivityTile(context, group));
      lastMonthKey = monthKey;
    }
    return widgets;
  }

  Widget _buildMonthHeader(BuildContext context, DateTime date) {
    final scheme = context.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.lg.w,
        AppDimensions.md.h,
        AppDimensions.lg.w,
        AppDimensions.xs.h,
      ),
      child: Text(
        DateFormat('MMMM yyyy').format(date),
        style: context.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildGroupActivityTile(
    BuildContext context,
    FriendGroupBalance group,
  ) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;
    final isOwed = group.amount > 0;
    final isSettled = group.amount.abs() < 0.01;

    return InkWell(
      onTap: () async {
        await context.pushNamed(
          RouteConstants.groupDetailName,
          pathParameters: {'groupId': group.groupId},
        );
        if (mounted) _load();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.lg.w,
          vertical: AppDimensions.sm.h,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 32.w,
                child: Text(
                  DateFormat('d\nMMM').format(group.lastActivityDate),
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.md.w),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              SizedBox(width: AppDimensions.md.w),
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.receipt_long,
                  size: 16.r,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              SizedBox(width: AppDimensions.sm.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      group.groupName,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      group.expenseCount > 1
                          ? 'Shared group'
                          : 'Shared expense',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppDimensions.sm.w),
              if (!isSettled)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isOwed ? 'you lent' : 'you owe',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${group.currencySymbol}${group.amount.abs().toStringAsFixed(2)}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOwed
                            ? appColors.positiveBalanceColor
                            : appColors.negativeBalanceColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    AppToast.show(context, 'Coming soon!', type: ToastType.info);
  }
}
