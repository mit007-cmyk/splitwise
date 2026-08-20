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
        event.type == ActivityEventType.settlementAdded ||
        event.type == ActivityEventType.settlementUpdated ||
        event.type == ActivityEventType.settlementDeleted;
  }

  String _titleOf(ActivityEvent event) {
    final title = (event.metadata['title'] as String?)?.trim();
    if (title != null && title.isNotEmpty) return title;
    return 'expense';
  }

  String _groupNameOf(ActivityEvent event) {
    final name = (event.metadata['groupName'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'group';
  }

  bool _changedAny(ActivityEvent event, List<String> fields) {
    return event.changedFields.any(fields.contains);
  }

  String _quoted(String value) => '"$value"';

  String _otherName(
    ActivityState state,
    String currentUserId,
    ActivityEvent event,
  ) {
    final fromMetadata = event.metadata['otherUserId'] as String?;
    String? otherId = fromMetadata?.trim();
    if (otherId == null || otherId.isEmpty) {
      final participants = event.metadata['participants'];
      if (participants is List) {
        for (final id in participants) {
          final value = id.toString();
          if (value.isNotEmpty && value != event.performedBy) {
            otherId = value;
            break;
          }
        }
      }
    }
    return otherId == null
        ? 'Splitwise user'
        : _personName(state, currentUserId, otherId);
  }

  String _friendName(
    ActivityState state,
    String currentUserId,
    ActivityEvent event,
  ) {
    final id = (event.metadata['friendUserId'] as String?) ?? event.entityId;
    return _personName(
      state,
      currentUserId,
      id,
      fallback: event.metadata['friendName'] as String?,
    );
  }

  String _memberName(
    ActivityState state,
    String currentUserId,
    ActivityEvent event,
  ) {
    final memberId = (event.metadata['memberUserId'] as String?) ?? '';
    return _personName(
      state,
      currentUserId,
      memberId,
      fallback: event.metadata['memberName'] as String?,
    );
  }

  InlineSpan _headlineSpan(
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
    final title = _titleOf(event);
    final groupName = _groupNameOf(event);

    if (_isSettlement(event)) {
      final otherName = _otherName(state, currentUserId, event);
      switch (event.type) {
        case ActivityEventType.settlementUpdated:
        case ActivityEventType.expenseUpdated:
          return TextSpan(
            style: base,
            children: [
              boldText(actor),
              plain(' edited a payment in '),
              boldText(_quoted(groupName)),
              plain('.'),
            ],
          );
        case ActivityEventType.settlementDeleted:
        case ActivityEventType.expenseDeleted:
          return TextSpan(
            style: base,
            children: [
              boldText(actor),
              plain(' cancelled a payment in '),
              boldText(_quoted(groupName)),
              plain('.'),
            ],
          );
        default:
          final direction = (event.metadata['netDirection'] as String?) ?? '';
          if (direction == 'owe') {
            return TextSpan(
              style: base,
              children: [
                boldText(actor),
                plain(' recorded a payment from '),
                boldText(otherName),
                plain(' in '),
                boldText(_quoted(groupName)),
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
              boldText(_quoted(groupName)),
              plain('.'),
            ],
          );
      }
    }

    switch (event.type) {
      case ActivityEventType.expenseCreated:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' added '),
            boldText(_quoted(title)),
            plain(' in '),
            boldText(_quoted(groupName)),
            plain('.'),
          ],
        );
      case ActivityEventType.expenseUpdated:
        if (_changedAny(event, const ['category', 'categoryId']) &&
            !_changedAny(event, const ['amount'])) {
          final category = (event.metadata['category'] as String?)?.trim();
          return TextSpan(
            style: base,
            children: [
              boldText(actor),
              plain(' changed '),
              boldText(_quoted(title)),
              plain(' category'),
              if (category != null && category.isNotEmpty) ...[
                plain(' to '),
                boldText(category),
              ],
              plain(' in '),
              boldText(_quoted(groupName)),
              plain('.'),
            ],
          );
        }
        if (_changedAny(event, const [
              'splits',
              'paidBy',
              'splitType',
              'participantIds',
            ]) &&
            !_changedAny(event, const ['amount', 'category', 'categoryId'])) {
          return TextSpan(
            style: base,
            children: [
              boldText(actor),
              plain(' changed the split for '),
              boldText(_quoted(title)),
              plain(' in '),
              boldText(_quoted(groupName)),
              plain('.'),
            ],
          );
        }
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' edited '),
            boldText(_quoted(title)),
            plain(' in '),
            boldText(_quoted(groupName)),
            plain('.'),
          ],
        );
      case ActivityEventType.expenseDeleted:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' deleted '),
            boldText(_quoted(title)),
            plain(' in '),
            boldText(_quoted(groupName)),
            plain('.'),
          ],
        );
      case ActivityEventType.expenseRestored:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' restored '),
            boldText(_quoted(title)),
            plain(' in '),
            boldText(_quoted(groupName)),
            plain('.'),
          ],
        );
      case ActivityEventType.commentAdded:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' commented on '),
            boldText(_quoted(title)),
            plain('.'),
          ],
        );
      case ActivityEventType.commentEdited:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' edited a comment on '),
            boldText(_quoted(title)),
            plain('.'),
          ],
        );
      case ActivityEventType.commentDeleted:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' deleted a comment on '),
            boldText(_quoted(title)),
            plain('.'),
          ],
        );
      case ActivityEventType.groupCreated:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' created the group '),
            boldText(_quoted(groupName)),
            plain('.'),
          ],
        );
      case ActivityEventType.groupDeleted:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' deleted the group '),
            boldText(_quoted(groupName)),
            plain('.'),
          ],
        );
      case ActivityEventType.groupUpdated:
        if (event.changedFields.contains('name')) {
          final previous =
              (event.metadata['previousGroupName'] as String?)?.trim();
          return TextSpan(
            style: base,
            children: [
              boldText(actor),
              plain(' changed group name'),
              if (previous != null && previous.isNotEmpty) ...[
                plain(' from '),
                boldText(_quoted(previous)),
              ],
              plain(' to '),
              boldText(_quoted(groupName)),
              plain('.'),
            ],
          );
        }
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' changed settings for the group '),
            boldText(_quoted(groupName)),
            plain('.'),
          ],
        );
      case ActivityEventType.memberJoinedGroup:
        final joinKind = (event.metadata['joinKind'] as String?) ?? 'added';
        final memberName = _memberName(state, currentUserId, event);
        if (joinKind == 'joined' ||
            event.performedBy == (event.metadata['memberUserId'] as String?)) {
          return TextSpan(
            style: base,
            children: [
              boldText(actor),
              plain(' joined the group '),
              boldText(_quoted(groupName)),
              plain('.'),
            ],
          );
        }
        if (joinKind == 'invited') {
          return TextSpan(
            style: base,
            children: [
              boldText(actor),
              plain(' invited '),
              boldText(memberName),
              plain(' to the group '),
              boldText(_quoted(groupName)),
              plain('.'),
            ],
          );
        }
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' added '),
            boldText(memberName),
            plain(' to the group '),
            boldText(_quoted(groupName)),
            plain('.'),
          ],
        );
      case ActivityEventType.memberLeftGroup:
        final joinKind = (event.metadata['joinKind'] as String?) ?? 'left';
        final memberName = _memberName(state, currentUserId, event);
        if (joinKind == 'removed') {
          return TextSpan(
            style: base,
            children: [
              boldText(actor),
              plain(' removed '),
              boldText(memberName),
              plain(' from the group '),
              boldText(_quoted(groupName)),
              plain('.'),
            ],
          );
        }
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' left the group '),
            boldText(_quoted(groupName)),
            plain('.'),
          ],
        );
      case ActivityEventType.friendAdded:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' added '),
            boldText(_friendName(state, currentUserId, event)),
            plain(' as a friend.'),
          ],
        );
      case ActivityEventType.friendRemoved:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' removed '),
            boldText(_friendName(state, currentUserId, event)),
            plain(' from friends.'),
          ],
        );
      case ActivityEventType.friendRequestSent:
        final friendId =
            (event.metadata['friendUserId'] as String?) ?? event.entityId;
        if (friendId == currentUserId) {
          return TextSpan(
            style: base,
            children: [
              boldText(actor),
              plain(' sent you a friend request.'),
            ],
          );
        }
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' sent a friend request to '),
            boldText(_friendName(state, currentUserId, event)),
            plain('.'),
          ],
        );
      case ActivityEventType.friendRequestAccepted:
        final friendId =
            (event.metadata['friendUserId'] as String?) ?? event.entityId;
        if (friendId == currentUserId) {
          return TextSpan(
            style: base,
            children: [
              boldText(actor),
              plain(' accepted your friend request.'),
            ],
          );
        }
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' accepted '),
            boldText(_friendName(state, currentUserId, event)),
            plain("'s friend request."),
          ],
        );
      case ActivityEventType.userBlocked:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' blocked '),
            boldText(
              _personName(
                state,
                currentUserId,
                event.entityId,
                fallback: event.metadata['blockedUserName'] as String?,
              ),
            ),
            plain('. This notification is only visible to you.'),
          ],
        );
      case ActivityEventType.userUnblocked:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' unblocked '),
            boldText(
              _personName(
                state,
                currentUserId,
                event.entityId,
                fallback: event.metadata['unblockedUserName'] as String?,
              ),
            ),
            plain('. This notification is only visible to you.'),
          ],
        );
      default:
        return TextSpan(
          style: base,
          children: [
            boldText(actor),
            plain(' ${event.type.value.replaceAll('_', ' ')}.'),
          ],
        );
    }
  }

  bool _isDeletedExpenseEvent(ActivityEvent event) {
    return event.type == ActivityEventType.expenseDeleted ||
        event.type == ActivityEventType.settlementDeleted ||
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
    if (direction == 'owed') {
      return 'You get back $symbol${amount.toStringAsFixed(2)}';
    }
    if (direction == 'owe') {
      return 'You owe $symbol${amount.toStringAsFixed(2)}';
    }
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
      case ActivityEventType.groupUpdated:
      case ActivityEventType.groupDeleted:
      case ActivityEventType.memberJoinedGroup:
      case ActivityEventType.memberLeftGroup:
        return Icons.list_alt_rounded;
      case ActivityEventType.friendAdded:
      case ActivityEventType.friendRemoved:
      case ActivityEventType.friendRequestSent:
      case ActivityEventType.friendRequestAccepted:
        return Icons.person_outline_rounded;
      case ActivityEventType.userBlocked:
      case ActivityEventType.userUnblocked:
        return Icons.person_off_outlined;
      case ActivityEventType.commentAdded:
      case ActivityEventType.commentEdited:
      case ActivityEventType.commentDeleted:
        return Icons.chat_bubble_outline_rounded;
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
      case ActivityEventType.groupUpdated:
      case ActivityEventType.memberJoinedGroup:
      case ActivityEventType.memberLeftGroup:
        return const Color(0xFF6B2D3C).withValues(alpha: 0.55);
      case ActivityEventType.friendAdded:
      case ActivityEventType.friendRemoved:
      case ActivityEventType.friendRequestSent:
      case ActivityEventType.friendRequestAccepted:
        return scheme.secondaryContainer.withValues(alpha: 0.7);
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
          event.type == ActivityEventType.settlementDeleted ||
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
                    _headlineSpan(context, state, currentUserId, item),
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
