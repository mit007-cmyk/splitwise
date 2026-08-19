import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/utils/csv_exporter.dart';
import '../../../../core/utils/currency_amount.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/geometric_identicon.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/services/direct_group.dart';
import '../../../expenses/domain/services/friend_ledger.dart';
import '../../../expenses/presentation/pages/expense_detail_page.dart';
import '../../../expenses/presentation/widgets/category_picker_sheet.dart';
import '../../../expenses/presentation/utils/currency_conversion_action.dart';
import '../../domain/entities/user_preview.dart';
import '../bloc/friend_detail_cubit.dart';
import '../../../../core/widgets/app_toast.dart';
import '../widgets/add_expense_extended_fab.dart';
import '../widgets/friend_action_pill.dart';
import '../widgets/friend_expenses_empty_state.dart';
import '../widgets/friend_reminder_sheet.dart';
import 'friend_record_payment_page.dart';

class FriendDetailPage extends StatefulWidget {
  final String friendId;

  const FriendDetailPage({super.key, required this.friendId});

  @override
  State<FriendDetailPage> createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends State<FriendDetailPage> {
  late final FriendDetailCubit _cubit;
  late final ScrollController _scrollController;
  bool _breakdownExpanded = true;
  bool _isCollapsed = false;
  String? _defaultCurrencyCode;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<FriendDetailCubit>();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _scrollListener() {
    if (!mounted || !_scrollController.hasClients) return;
    final threshold =
        180.h - kToolbarHeight - MediaQuery.of(context).padding.top;
    final collapsed = _scrollController.offset >= threshold;
    if (collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }
  }

  void _load() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _cubit.load(currentUserId: authState.user.id, friendId: widget.friendId);
      _loadDefaultCurrency(authState.user.id);
    }
  }

  Future<void> _loadDefaultCurrency(String userId) async {
    try {
      final code = await CurrencyConversionAction.defaultCode(userId);
      if (mounted) setState(() => _defaultCurrencyCode = code);
    } catch (_) {
      if (mounted) setState(() => _defaultCurrencyCode = 'USD');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
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
    final heroColor = identiconPrimaryColor(friend.name);
    final overallAmounts = state.overallAmounts;

    final avatarSize = 70.w;
    final expandedHeight = 180.h;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        RefreshIndicator(
          onRefresh: () async => _load(),
          child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: expandedHeight,
                  backgroundColor: heroColor,
                  elevation: 0,
                  centerTitle: false,
                  title: _isCollapsed
                      ? Text(
                          friend.name,
                          style: context.textTheme.titleLarge?.copyWith(
                            color: appColors.onImageColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                  leading: Padding(
                    padding: EdgeInsets.only(left: 8.w, top: 4.h, bottom: 4.h),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: appColors.onImageColor),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            appColors.overlayColor.withValues(alpha: 0.3),
                        shape: const CircleBorder(),
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.w, top: 4.h, bottom: 4.h),
                      child: IconButton(
                        icon: Icon(
                          Icons.settings_outlined,
                          color: appColors.onImageColor,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              appColors.overlayColor.withValues(alpha: 0.3),
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
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: GeometricIdenticon(
                      seed: friend.name,
                      clipToCircle: false,
                    ),
                  ),
                ),
              ];
            },
            body: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: 96.h),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimensions.xxl.w,
                    _isCollapsed ? AppDimensions.lg.h : 52.h,
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
                              thickness: 1.w,
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
                                  if (friend.contactLine != null) ...[
                                    SizedBox(height: AppDimensions.xs.h),
                                    Text(
                                      friend.contactLine!,
                                      style: context.textTheme.bodySmall
                                          ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: AppDimensions.sm.h),
                                  _buildBalanceBreakdown(
                                    context,
                                    state,
                                    friend.name,
                                    overallAmounts,
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
                              onTap: () =>
                                  _openSettleUp(context, state, friend),
                            ),
                            FriendActionPill(
                              label: 'Remind...',
                              onTap: () =>
                                  _openRemindSheet(context, state, friend),
                            ),
                            FriendActionPill(
                              label: 'Charts',
                              icon: Icons.diamond_rounded,
                              onTap: () => _showComingSoon(context),
                            ),
                            if (CurrencyConversionAction.shouldShow(
                              state.entries.map((entry) => entry.expense).toList(),
                              _defaultCurrencyCode,
                            ))
                              FriendActionPill(
                                label: CurrencyConversionAction.buttonLabel(
                                  _defaultCurrencyCode ?? 'USD',
                                ),
                                leading: CurrencyConversionAction.buttonIcon(
                                  defaultCode: _defaultCurrencyCode ?? 'USD',
                                  color: context.colorScheme.secondary,
                                  size: 16.r,
                                ),
                                onTap: () => _convertCurrencies(context, state),
                              ),
                            FriendActionPill(
                              label: 'Export',
                              icon: Icons.download_rounded,
                              onTap: () => _exportFriendExpenses(
                                context,
                                state,
                                friend,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_visibleEntries(state).isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: FriendExpensesEmptyState(),
                  )
                else
                  Padding(
                    padding: EdgeInsets.only(top: AppDimensions.lg.h),
                    child: Column(
                      children: _buildActivityFeed(context, state),
                    ),
                  ),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _scrollController,
          builder: (context, child) {
            if (_isCollapsed) return const SizedBox.shrink();

            final collapsedHeight =
                kToolbarHeight + MediaQuery.of(context).padding.top;
            final offset =
                _scrollController.hasClients ? _scrollController.offset : 0.0;
            final headerBottom =
                (expandedHeight - offset).clamp(collapsedHeight, expandedHeight);

            return Positioned(
              top: headerBottom - 40.h,
              left: AppDimensions.xxl.w,
              child: child!,
            );
          },
          child: AvatarWidget(
            name: friend.name,
            imageUrl: friend.photoUrl,
            size: avatarSize,
          ),
        ),
      ],
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
    List<CurrencyAmount> amounts,
  ) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;
    final breakdown = state.groupBalances;
    final isSettled = amounts.isEmpty;
    final hasOwed = amounts.any((item) => item.isOwed);
    final hasOwe = amounts.any((item) => item.isOwe);
    final balanceColor = isSettled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.75)
        : hasOwed && hasOwe
        ? scheme.onSurface
        : hasOwed
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
                    : MultiCurrency.overallLabel(
                        amounts: amounts,
                        owedPrefix: 'You are owed',
                        owePrefix: 'You owe',
                        settled: 'You are all settled up.',
                      ) +
                        (MultiCurrency.netByCurrency(amounts).length == 1
                            ? ' overall'
                            : ''),
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

  List<FriendExpenseEntry> _visibleEntries(FriendDetailState state) {
    return state.entries
        .where((entry) => !entry.expense.isDeleted)
        .toList();
  }

  /// Direct expenses are one row each. Group expenses collapse to a single
  /// row per group, sorted by that group's most recent expense so a new
  /// group spend jumps to the top of the feed.
  List<Widget> _buildActivityFeed(
    BuildContext context,
    FriendDetailState state,
  ) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId =
        authState is Authenticated ? authState.user.id : '';
    final friendId = state.friend?.id ?? '';
    final friendName = state.friend?.name ?? '';

    final directs = <FriendExpenseEntry>[];
    final byGroup = <String, List<FriendExpenseEntry>>{};
    for (final entry in _visibleEntries(state)) {
      if (_isDirectExpense(entry.expense, currentUserId, friendId)) {
        directs.add(entry);
      } else {
        byGroup.putIfAbsent(entry.expense.groupId, () => []).add(entry);
      }
    }

    final dated = <({DateTime date, FriendExpenseEntry? direct, String? groupId})>[
      for (final entry in directs)
        (date: entry.expense.date, direct: entry, groupId: null),
      for (final group in byGroup.entries)
        (
          date: group.value
              .map((entry) => entry.expense.date)
              .reduce((a, b) => a.isAfter(b) ? a : b),
          direct: null,
          groupId: group.key,
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final widgets = <Widget>[];
    int? lastMonthKey;
    for (final item in dated) {
      final monthKey = item.date.year * 12 + item.date.month;
      if (lastMonthKey != null && monthKey != lastMonthKey) {
        widgets.add(_buildMonthHeader(context, item.date));
      }
      if (item.direct != null) {
        widgets.add(
          _buildDirectActivityTile(
            context,
            state,
            item.direct!,
            currentUserId: currentUserId,
            friendName: friendName,
          ),
        );
      } else {
        widgets.add(
          _buildGroupActivityTile(
            context,
            state,
            groupId: item.groupId!,
            entries: byGroup[item.groupId]!,
          ),
        );
      }
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

  bool _isDirectExpense(
    Expense expense,
    String currentUserId,
    String friendId,
  ) {
    final groupId = expense.groupId.trim();
    if (groupId.isEmpty || groupId.startsWith('direct_')) return true;
    if (currentUserId.isEmpty || friendId.isEmpty) return false;
    return groupId == DirectGroup.idFor(currentUserId, friendId);
  }

  String _directPaidSubtitle(
    Expense expense,
    String currentUserId,
    String friendName,
  ) {
    final paidByMe = expense.paidBy[currentUserId] ?? 0.0;
    if (paidByMe > 0.01) {
      return 'You paid ${expense.currencySymbol}${paidByMe.toStringAsFixed(2)}';
    }

    var topPayerId = '';
    var topPayerAmount = 0.0;
    expense.paidBy.forEach((id, amount) {
      if (amount > topPayerAmount) {
        topPayerId = id;
        topPayerAmount = amount;
      }
    });
    final amount =
        '${expense.currencySymbol}${topPayerAmount.toStringAsFixed(2)}';
    if (topPayerId == currentUserId) return 'You paid $amount';
    return '${friendName.isEmpty ? 'Someone' : friendName} paid $amount';
  }

  Widget _activityIcon({
    required bool isDirect,
    required String groupName,
    required String category,
  }) {
    final size = 40.w;
    if (isDirect) {
      return ExpenseCategoryGlyph(category: category, size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GeometricIdenticon(seed: groupName, clipToCircle: false),
            Center(
              child: Icon(
                ExpenseCategory.iconFor(category),
                size: 18.r,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectActivityTile(
    BuildContext context,
    FriendDetailState state,
    FriendExpenseEntry entry, {
    required String currentUserId,
    required String friendName,
  }) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;
    final expense = entry.expense;
    final isOwed = entry.amount > 0;
    final isSettled = entry.amount.abs() < 0.01;

    return InkWell(
      onTap: () => _openExpense(context, state, entry, currentUserId),
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
                  DateFormat('d\nMMM').format(expense.date),
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
              _activityIcon(
                isDirect: true,
                groupName: expense.title,
                category: expense.category,
              ),
              SizedBox(width: AppDimensions.sm.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      expense.title,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _directPaidSubtitle(
                        expense,
                        currentUserId,
                        friendName,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                      '${expense.currencySymbol}${entry.amount.abs().toStringAsFixed(2)}',
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

  Widget _buildGroupActivityTile(
    BuildContext context,
    FriendDetailState state, {
    required String groupId,
    required List<FriendExpenseEntry> entries,
  }) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;
    final latest = entries.reduce(
      (a, b) => a.expense.date.isAfter(b.expense.date) ? a : b,
    );
    final groupName =
        state.groupNames[groupId] ?? latest.expense.title;
    final balances =
        state.groupBalances.where((row) => row.groupId == groupId).toList();

    late final double amount;
    late final String currencySymbol;
    if (balances.length == 1) {
      amount = balances.first.amount;
      currencySymbol = balances.first.currencySymbol;
    } else if (balances.isNotEmpty) {
      final match = balances.where(
        (row) => row.currencyCode == latest.expense.currencyCode,
      );
      final row = match.isNotEmpty ? match.first : balances.first;
      amount = row.amount;
      currencySymbol = row.currencySymbol;
    } else {
      amount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
      currencySymbol = latest.expense.currencySymbol;
    }

    final isOwed = amount > 0;
    final isSettled = amount.abs() < 0.01;

    return InkWell(
      onTap: () async {
        await context.pushNamed(
          RouteConstants.groupDetailName,
          pathParameters: {'groupId': groupId},
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
                  DateFormat('d\nMMM').format(latest.expense.date),
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
              _activityIcon(
                isDirect: false,
                groupName: groupName,
                category: latest.expense.category,
              ),
              SizedBox(width: AppDimensions.sm.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      groupName,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Shared group',
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
                      '$currencySymbol${amount.abs().toStringAsFixed(2)}',
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

  Future<void> _openExpense(
    BuildContext context,
    FriendDetailState state,
    FriendExpenseEntry entry,
    String currentUserId,
  ) async {
    if (currentUserId.isEmpty) return;
    final friend = state.friend;
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExpenseDetailPage(
          expense: entry.expense,
          memberNames: {
            currentUserId: 'You',
            if (friend != null) friend.id: friend.name,
          },
          currentUserId: currentUserId,
          groupName: state.groupNames[entry.expense.groupId],
        ),
      ),
    );
    if (deleted == true && mounted) {
      _load();
    }
  }

  Future<void> _convertCurrencies(
    BuildContext context,
    FriendDetailState state,
  ) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      AppToast.show(context, 'Please log in again.', type: ToastType.error);
      return;
    }

    final converted = await CurrencyConversionAction.confirmAndRun(
      context: context,
      actorUserId: authState.user.id,
      expenses: state.entries.map((entry) => entry.expense).toList(),
      scopeLabel: 'friendship',
    );
    if (converted && mounted) _load();
  }

  void _showComingSoon(BuildContext context) {
    AppToast.show(context, 'Coming soon!', type: ToastType.info);
  }

  Future<void> _openRemindSheet(
    BuildContext context,
    FriendDetailState state,
    UserPreview friend,
  ) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      AppToast.show(context, 'Please log in again.', type: ToastType.error);
      return;
    }

    if (state.groupBalances.isEmpty) {
      AppToast.show(context, 'You are all settled up.', type: ToastType.info);
      return;
    }

    await FriendReminderSheet.show(
      context,
      friendName: friend.name,
      outstandingBalanceCount: state.groupBalances.length,
      currentUserId: authState.user.id,
      currentUserName: authState.user.name,
      currentUserPhotoUrl: authState.user.photoUrl,
    );
  }

  /// CSV of every expense shared with this friend, with one net column per
  /// side so the running balance in the file matches the on-screen totals.
  Future<void> _exportFriendExpenses(
    BuildContext context,
    FriendDetailState state,
    UserPreview friend,
  ) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      AppToast.show(context, 'Please log in again.', type: ToastType.error);
      return;
    }

    final entries = state.entries
        .where((entry) => !entry.expense.isDeleted)
        .toList();
    if (entries.isEmpty) {
      AppToast.show(context, 'No expenses to export.', type: ToastType.info);
      return;
    }

    final currentUserId = authState.user.id;
    final csvRows = <String>[];
    final headers = [
      'Date',
      'Description',
      'Category',
      'Group',
      'Cost',
      'Currency',
      'You',
      friend.name,
    ];
    csvRows.add(headers.map(_escapeCsvField).join(','));
    csvRows.add('');

    var youNetTotal = 0.0;
    var friendNetTotal = 0.0;

    for (final entry in entries) {
      final expense = entry.expense;
      final youNet = (expense.paidBy[currentUserId] ?? 0.0) -
          (expense.splits[currentUserId] ?? 0.0);
      final friendNet =
          (expense.paidBy[friend.id] ?? 0.0) - (expense.splits[friend.id] ?? 0.0);
      youNetTotal += youNet;
      friendNetTotal += friendNet;

      csvRows.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.title,
        expense.category,
        state.groupNames[expense.groupId] ?? '',
        expense.amount.toStringAsFixed(2),
        expense.currencyCode,
        youNet.toStringAsFixed(2),
        friendNet.toStringAsFixed(2),
      ].map(_escapeCsvField).join(','));
    }

    csvRows.add('');
    csvRows.add([
      DateFormat('yyyy-MM-dd').format(entries.first.expense.date),
      'Total balance',
      ' ',
      ' ',
      ' ',
      entries.first.expense.currencyCode,
      youNetTotal.toStringAsFixed(2),
      friendNetTotal.toStringAsFixed(2),
    ].map(_escapeCsvField).join(','));
    csvRows.add('');
    csvRows.add('');

    final safeName = friend.name.replaceAll(RegExp(r'[^\w\s\-]'), '_');
    try {
      saveCsvFile(csvRows.join('\n'), '${safeName}_export.csv');
      if (context.mounted) {
        AppToast.show(context, 'Expenses exported successfully.', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(context, 'Failed to export CSV: $e', type: ToastType.error);
      }
    }
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Prefer the sole shared group, otherwise the group with the largest
  /// outstanding balance so the settlement expense is always attached to a
  /// real group (empty groupId settlements never clear the friend balance).
  String? _resolveSettleGroupId(FriendDetailState state) {
    if (state.soleSharedGroupId != null &&
        state.soleSharedGroupId!.trim().isNotEmpty) {
      return state.soleSharedGroupId;
    }
    if (state.groupBalances.isNotEmpty) {
      return state.groupBalances.first.groupId;
    }
    for (final entry in state.entries) {
      final groupId = entry.expense.groupId.trim();
      if (groupId.isNotEmpty) return groupId;
    }
    return null;
  }

  Future<void> _openSettleUp(
    BuildContext context,
    FriendDetailState state,
    UserPreview friend,
  ) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      AppToast.show(context, 'Please log in again.', type: ToastType.error);
      return;
    }

    if (state.isSettled) {
      AppToast.show(context, 'You are already settled up.', type: ToastType.info);
      return;
    }

    final amounts = state.overallAmounts;
    final toSettle = amounts.first;
    final groupId = _resolveSettleGroupId(state);
    if (groupId == null || groupId.isEmpty) {
      AppToast.show(
        context,
        'No shared group found to record this payment.',
        type: ToastType.error,
      );
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FriendRecordPaymentPage(
          currentUserId: authState.user.id,
          friendId: friend.id,
          friendName: friend.name,
          friendEmail: friend.email,
          friendPhotoUrl: friend.photoUrl,
          balance: toSettle.amount,
          currencyCode: toSettle.currencyCode,
          currencySymbol: toSettle.currencySymbol,
          groupId: groupId,
        ),
      ),
    );

    if (saved == true && mounted) {
      _load();
    }
  }
}
