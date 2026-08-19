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
import '../../../expenses/presentation/widgets/category_picker_sheet.dart';
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

  String _personName(
    ActivityState state,
    String currentUserId,
    String userId, {
    String? fallback,
  }) {
    if (userId == currentUserId) return 'You';
    final fromState = state.userNames[userId]?.trim();
    if (fromState != null && fromState.isNotEmpty) return fromState;
    final trimmed = fallback?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return 'Splitwise user';
  }

  bool _isSettlement(ActivityEvent event) {
    final category = (event.metadata['category'] as String?)?.toLowerCase() ?? '';
    return category == 'settlement' ||
        event.type == ActivityEventType.settlementAdded;
  }

  String _line1(ActivityState state, String currentUserId, ActivityEvent event) {
    final actor = _actorName(state, currentUserId, event.performedBy);
    final title = (event.metadata['title'] as String?) ?? 'expense';
    final groupName = (event.metadata['groupName'] as String?) ?? 'group';
    switch (event.type) {
      case ActivityEventType.expenseCreated:
        if (_isSettlement(event)) {
          return _settlementLine(state, currentUserId, event, actor, groupName);
        }
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
      case ActivityEventType.memberJoinedGroup:
        final memberId = (event.metadata['memberUserId'] as String?) ?? '';
        final memberName = _personName(
          state,
          currentUserId,
          memberId,
          fallback: event.metadata['memberName'] as String?,
        );
        return '$actor added $memberName to the group "$groupName".';
      case ActivityEventType.userBlocked:
        final name = _personName(
          state,
          currentUserId,
          event.entityId,
          fallback: event.metadata['blockedUserName'] as String?,
        );
        return '$actor blocked $name. This notification is only visible to you.';
      case ActivityEventType.userUnblocked:
        final name = _personName(
          state,
          currentUserId,
          event.entityId,
          fallback: event.metadata['unblockedUserName'] as String?,
        );
        return '$actor unblocked $name. This notification is only visible to you.';
      default:
        return '$actor performed ${event.type.value.replaceAll('_', ' ')}.';
    }
  }

  String _settlementLine(
    ActivityState state,
    String currentUserId,
    ActivityEvent event,
    String actor,
    String groupName,
  ) {
    final participants = event.metadata['participants'];
    String? otherId;
    if (participants is List) {
      for (final id in participants) {
        final value = id.toString();
        if (value.isNotEmpty && value != event.performedBy) {
          otherId = value;
          break;
        }
      }
    }
    final otherName = otherId == null
        ? 'Splitwise user'
        : _personName(state, currentUserId, otherId);
    final direction = (event.metadata['netDirection'] as String?) ?? '';
    if (direction == 'owe') {
      return '$actor recorded a payment from $otherName in "$groupName".';
    }
    return '$actor paid $otherName in "$groupName".';
  }

  InlineSpan _line1Span(
    BuildContext context,
    ActivityState state,
    String currentUserId,
    ActivityEvent event,
  ) {
    final base = context.textTheme.bodyMedium?.copyWith(
      color: context.colorScheme.onSurface,
      height: 1.25,
    );
    final bold = base?.copyWith(fontWeight: FontWeight.w700);

    TextSpan boldText(String text) => TextSpan(text: text, style: bold);
    TextSpan plain(String text) => TextSpan(text: text, style: base);

    final actor = _actorName(state, currentUserId, event.performedBy);
    final title = (event.metadata['title'] as String?) ?? 'expense';
    final groupName = (event.metadata['groupName'] as String?) ?? 'group';

    switch (event.type) {
      case ActivityEventType.userBlocked:
        final name = _personName(
          state,
          currentUserId,
          event.entityId,
          fallback: event.metadata['blockedUserName'] as String?,
        );
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' blocked '),
            boldText(name),
            plain('. This notification is only visible to you.'),
          ],
        );
      case ActivityEventType.userUnblocked:
        final name = _personName(
          state,
          currentUserId,
          event.entityId,
          fallback: event.metadata['unblockedUserName'] as String?,
        );
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' unblocked '),
            boldText(name),
            plain('. This notification is only visible to you.'),
          ],
        );
      case ActivityEventType.memberJoinedGroup:
        final memberId = (event.metadata['memberUserId'] as String?) ?? '';
        final memberName = _personName(
          state,
          currentUserId,
          memberId,
          fallback: event.metadata['memberName'] as String?,
        );
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' added '),
            plain(memberName),
            plain(' to the group '),
            boldText('"$groupName"'),
            plain('.'),
          ],
        );
      case ActivityEventType.groupCreated:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' created the group '),
            boldText('"$groupName"'),
            plain('.'),
          ],
        );
      case ActivityEventType.expenseCreated:
        if (_isSettlement(event)) {
          final participants = event.metadata['participants'];
          String? otherId;
          if (participants is List) {
            for (final id in participants) {
              final value = id.toString();
              if (value.isNotEmpty && value != event.performedBy) {
                otherId = value;
                break;
              }
            }
          }
          final otherName = otherId == null
              ? 'Splitwise user'
              : _personName(state, currentUserId, otherId);
          final direction = (event.metadata['netDirection'] as String?) ?? '';
          if (direction == 'owe') {
            return TextSpan(
              style: base,
              children: [
                boldText(actor),
                plain(' recorded a payment from '),
                boldText(otherName),
                plain(' in '),
                boldText('"$groupName"'),
                plain('.'),
              ],
            );
          }
          return TextSpan(
            style: base,
            children: [
              boldText(actor),
              plain(' paid '),
              boldText(otherName),
              plain(' in '),
              boldText('"$groupName"'),
              plain('.'),
            ],
          );
        }
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' added '),
            boldText('"$title"'),
            plain(' in '),
            boldText('"$groupName"'),
            plain('.'),
          ],
        );
      default:
        return TextSpan(text: _line1(state, currentUserId, event), style: base);
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
    if (_isSettlement(event)) {
      if (direction == 'owed') {
        return 'You paid $symbol${amount.toStringAsFixed(2)}';
      }
      if (direction == 'owe') {
        return 'You received $symbol${amount.toStringAsFixed(2)}';
      }
    }
    if (direction == 'owed') return 'You get back $symbol${amount.toStringAsFixed(2)}';
    if (direction == 'owe') return 'You owe $symbol${amount.toStringAsFixed(2)}';
    return null;
  }

  TextStyle _line2Style(BuildContext context, ActivityEvent event) {
    final direction = (event.metadata['netDirection'] as String?) ?? '';
    final isDeleted = _isDeletedExpenseEvent(event);
    final isSettlement = _isSettlement(event);
    final Color amountColor;
    if (isSettlement) {
      amountColor = direction == 'owe'
          ? context.appColors.negativeBalanceColor
          : context.appColors.positiveBalanceColor;
    } else {
      amountColor = direction == 'owe'
          ? context.appColors.negativeBalanceColor
          : context.appColors.positiveBalanceColor;
    }

    return context.textTheme.bodyMedium!.copyWith(
      color: isDeleted ? amountColor.withValues(alpha: 0.75) : amountColor,
      fontWeight: FontWeight.w600,
      decoration: isDeleted ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: amountColor,
      decorationThickness: 1.5,
    );
  }

  String _relativeTimestamp(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    final time = DateFormat('h:mm a').format(date).toLowerCase();
    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Yesterday, $time';
    if (diff < 7) return '$diff days ago, $time';
    return '${DateFormat('dd MMM yyyy').format(date)}, $time';
  }

  IconData _iconForEvent(ActivityEvent event) {
    if (_isSettlement(event)) return Icons.payments_outlined;
    switch (event.type) {
      case ActivityEventType.groupCreated:
      case ActivityEventType.groupDeleted:
      case ActivityEventType.memberJoinedGroup:
      case ActivityEventType.memberLeftGroup:
        return Icons.list_alt_rounded;
      case ActivityEventType.userBlocked:
      case ActivityEventType.userUnblocked:
        return Icons.person_off_outlined;
      case ActivityEventType.expenseCreated:
      case ActivityEventType.expenseUpdated:
      case ActivityEventType.expenseDeleted:
      case ActivityEventType.expenseRestored:
        return ExpenseCategory.iconFor(_categoryForEvent(event));
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String? _categoryForEvent(ActivityEvent event) {
    final fromMetadata = event.metadata['category'] as String?;
    if (fromMetadata != null && fromMetadata.trim().isNotEmpty) {
      return fromMetadata;
    }
    final after = event.snapshotAfter?['category'] as String?;
    if (after != null && after.trim().isNotEmpty) return after;
    return event.snapshotBefore?['category'] as String?;
  }

  Color _iconBgForEvent(BuildContext context, ActivityEvent event) {
    final scheme = context.colorScheme;
    if (_isSettlement(event)) return scheme.primary.withValues(alpha: 0.2);
    switch (event.type) {
      case ActivityEventType.userBlocked:
      case ActivityEventType.userUnblocked:
        return scheme.primary.withValues(alpha: 0.18);
      case ActivityEventType.groupCreated:
      case ActivityEventType.memberJoinedGroup:
        return const Color(0xFF6B2D3C).withValues(alpha: 0.55);
      default:
        return scheme.primaryContainer.withValues(alpha: 0.55);
    }
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
            for (final item in state.items) {
              final line2 = _line2(item);
              widgets.add(
                ListTile(
                  onTap: () => _openEvent(context, state, item),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg.w,
                    vertical: 4.h,
                  ),
                  leading: CircleAvatar(
                    radius: 22.r,
                    backgroundColor: _iconBgForEvent(context, item),
                    child: Icon(
                      _iconForEvent(item),
                      color: context.colorScheme.onSurface,
                      size: 22.r,
                    ),
                  ),
                  title: Text.rich(
                    _line1Span(context, state, currentUserId, item),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (line2 != null)
                        Text(
                          line2,
                          style: _line2Style(context, item),
                        ),
                      Text(
                        _relativeTimestamp(item.performedAt),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
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
