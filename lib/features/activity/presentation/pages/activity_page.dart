import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../expenses/presentation/pages/expense_detail_page.dart';
import '../../domain/entities/activity_event.dart';
import '../bloc/activity_bloc.dart';
import '../bloc/activity_event.dart';
import '../bloc/activity_state.dart';
import 'activity_restore_expense_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ActivityBloc>().add(const LoadActivity());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _actorName(ActivityState state, String currentUserId, String actorId) {
    if (actorId == currentUserId) return 'You';
    return state.userNames[actorId] ?? 'Splitwise user';
  }

  String _line1(ActivityState state, String currentUserId, ActivityEvent event) {
    final actor = _actorName(state, currentUserId, event.performedBy);
    final title = (event.metadata['title'] as String?) ?? 'expense';
    final groupName = (event.metadata['groupName'] as String?) ?? 'group';
    switch (event.type) {
      case ActivityEventType.expenseCreated:
        return '$actor added "$title" in "$groupName".';
      case ActivityEventType.expenseUpdated:
        return '$actor edited "$title" in "$groupName".';
      case ActivityEventType.expenseDeleted:
        return '$actor deleted "$title" in "$groupName".';
      case ActivityEventType.expenseRestored:
        return '$actor restored "$title" in "$groupName".';
      case ActivityEventType.groupCreated:
        return '$actor created the group "$groupName".';
      case ActivityEventType.groupDeleted:
        return '$actor deleted the group "$groupName".';
      default:
        return '$actor performed ${event.type.value.replaceAll('_', ' ')}.';
    }
  }

  bool _isDeletedExpenseEvent(ActivityEvent event) {
    return event.type == ActivityEventType.expenseDeleted ||
        ((event.snapshotAfter?['isDeleted'] as bool?) ?? false);
  }

  String? _line2(ActivityEvent event) {
    final amount = (event.metadata['netAmount'] as num?)?.toDouble();
    final symbol = (event.metadata['currencySymbol'] as String?) ?? '';
    final direction = (event.metadata['netDirection'] as String?) ?? '';
    if (amount == null || amount <= 0) return null;
    if (direction == 'owed') return 'You get back $symbol${amount.toStringAsFixed(2)}';
    if (direction == 'owe') return 'You owe $symbol${amount.toStringAsFixed(2)}';
    return null;
  }

  TextStyle _line2Style(BuildContext context, ActivityEvent event) {
    final direction = (event.metadata['netDirection'] as String?) ?? '';
    final isDeleted = _isDeletedExpenseEvent(event);
    final amountColor = direction == 'owe'
        ? context.appColors.negativeBalanceColor
        : context.appColors.positiveBalanceColor;

    return context.textTheme.bodyMedium!.copyWith(
      color: isDeleted ? amountColor.withValues(alpha: 0.75) : amountColor,
      fontWeight: FontWeight.w600,
      decoration: isDeleted ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: amountColor,
      decorationThickness: 1.5,
    );
  }

  String _dateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> _openEvent(BuildContext context, ActivityState state, ActivityEvent event) async {
    final auth = context.read<AuthBloc>().state;
    final currentUserId = auth is Authenticated ? auth.user.id : '';
    final activityBloc = context.read<ActivityBloc>();
    if (event.entityType == 'expense') {
      if (event.type == ActivityEventType.expenseDeleted ||
          ((event.snapshotAfter?['isDeleted'] as bool?) ?? false)) {
        final restored = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ActivityRestoreExpensePage(
              event: event,
              currentUserId: currentUserId,
            ),
          ),
        );
        if (restored == true && context.mounted) {
          activityBloc.add(const RefreshActivity());
        }
        return;
      }
      final repo = getIt<ExpenseRepository>();
      final result = await repo.getExpenseById(event.entityId);
      if (!context.mounted) return;
      if (result.isSuccess && result.dataOrThrow != null) {
        final refreshed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ExpenseDetailPage(
              expense: result.dataOrThrow!,
              memberNames: state.userNames,
              currentUserId: currentUserId,
            ),
          ),
        );
        if (refreshed == true && context.mounted) {
          activityBloc.add(const RefreshActivity());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    final currentUserId = auth is Authenticated ? auth.user.id : '';
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        final activityBloc = context.read<ActivityBloc>();
        if (state is Authenticated &&
            activityBloc.state.items.isEmpty &&
            !activityBloc.state.isLoading) {
          activityBloc.add(const RefreshActivity());
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Activity')),
        body: BlocBuilder<ActivityBloc, ActivityState>(
          builder: (context, state) {
            if (state.isLoading && state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null && state.items.isEmpty) {
              return Center(child: Text(state.error!));
            }
            if (state.items.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ActivityBloc>().add(const RefreshActivity());
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
                    Center(
                      child: Text(
                        'No activity yet.',
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final widgets = <Widget>[];
            String? lastHeader;
            for (final item in state.items) {
              final header = _dateHeader(item.performedAt);
              if (header != lastHeader) {
                widgets.add(
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppDimensions.lg.w,
                      AppDimensions.md.h,
                      AppDimensions.lg.w,
                      AppDimensions.sm.h,
                    ),
                    child: Text(
                      header,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
                lastHeader = header;
              }
              final line2 = _line2(item);
              widgets.add(
                ListTile(
                  onTap: () => _openEvent(context, state, item),
                  leading: const CircleAvatar(
                    child: Icon(Icons.receipt_long_rounded),
                  ),
                  title: Text(_line1(state, currentUserId, item)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (line2 != null)
                        Text(
                          line2,
                          style: _line2Style(context, item),
                        ),
                      Text(
                        DateFormat('h:mm a').format(item.performedAt),
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state.isLoadingMore) {
              widgets.add(
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (state.hasMore) {
              widgets.add(
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<ActivityBloc>().add(const LoadAllActivity());
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(
                          color: context.colorScheme.primary.withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View all activity',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: context.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: context.colorScheme.primary,
                            size: 22.r,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ActivityBloc>().add(const RefreshActivity());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: widgets,
              ),
            );
          },
        ),
      ),
    );
  }
}
