import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/presentation/bloc/add_expense_bloc.dart';
import '../../../expenses/presentation/bloc/add_expense_event.dart';
import '../../../expenses/presentation/bloc/add_expense_state.dart';
import '../../../expenses/presentation/pages/adjust_split_page.dart';
import '../../../expenses/presentation/widgets/paid_by_sheet.dart';
import '../../../friends/domain/repositories/friends_repository.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../domain/entities/group_default_split.dart';
import '../../domain/repositories/group_user_settings_repository.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';

/// Configure the signed-in user's personal default split for one group.
/// Reuses Add Expense split UI; saved template prefills future expenses only.
class GroupDefaultSplitPage extends StatefulWidget {
  final String groupId;

  const GroupDefaultSplitPage({super.key, required this.groupId});

  @override
  State<GroupDefaultSplitPage> createState() => _GroupDefaultSplitPageState();
}

class _GroupDefaultSplitPageState extends State<GroupDefaultSplitPage> {
  late final AddExpenseBloc _bloc;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    var currentUserId = '';
    var currentUserName = 'You';
    if (authState is Authenticated) {
      currentUserId = authState.user.id;
      currentUserName = authState.user.name;
    }

    _bloc = AddExpenseBloc(
      expenseRepository: getIt<ExpenseRepository>(),
      homeRepository: getIt<HomeRepository>(),
      friendsRepository: getIt<FriendsRepository>(),
      groupUserSettingsRepository: getIt<GroupUserSettingsRepository>(),
      currentUserId: currentUserId,
      currentUserName: currentUserName,
    )..add(InitAddExpense(groupId: widget.groupId));

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedDefault());
  }

  Future<void> _loadSavedDefault() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() => _loading = false);
      return;
    }

    final result = await getIt<GroupUserSettingsRepository>().getDefaultSplit(
      groupId: widget.groupId,
      userId: authState.user.id,
    );

    if (!mounted) return;

    if (result.isSuccess && result.dataOrThrow != null) {
      final def = result.dataOrThrow!;
      _bloc.add(DefaultSplitApplied(
        paidByUserId: def.paidByUserId,
        splitType: def.splitType,
        selectedParticipantIds: def.selectedParticipantIds,
        splitValueTexts: def.splitValueTexts,
      ));
    } else {
      _bloc.add(const AmountChanged('100'));
    }

    if (_bloc.state.amountText.isEmpty) {
      _bloc.add(const AmountChanged('100'));
    }

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final state = _bloc.state;
    if (state.members.isEmpty) return;

    final draft = GroupDefaultSplit(
      groupId: widget.groupId,
      userId: authState.user.id,
      paidByUserId: state.singlePayerId ?? authState.user.id,
      splitType: state.splitType,
      selectedParticipantIds: state.selectedParticipantIds,
      splitValueTexts: state.splitValueTexts,
    );

    if (!draft.isValidForMembers(state.members.map((m) => m.id).toSet())) {
      AppToast.show(context, 'Fix the split before saving.', type: ToastType.error);
      return;
    }

    setState(() => _saving = true);
    final result = await getIt<GroupUserSettingsRepository>().saveDefaultSplit(draft);
    if (!mounted) return;

    setState(() => _saving = false);
    if (result.isFailure) {
      AppToast.show(context, 'Could not save default split.', type: ToastType.error);
      return;
    }

    AppToast.show(context, 'Default split saved.', type: ToastType.success);
    context.pop(true);
  }

  String _payerName(AddExpenseState state) {
    if (state.singlePayerId == state.currentUserId) return 'you';
    for (final member in state.members) {
      if (member.id == state.singlePayerId) return member.name;
    }
    return 'someone';
  }

  String _splitSummary(AddExpenseState state) {
    return GroupDefaultSplit(
      groupId: widget.groupId,
      userId: state.currentUserId,
      paidByUserId: state.singlePayerId ?? state.currentUserId,
      splitType: state.splitType,
      selectedParticipantIds: state.selectedParticipantIds,
      splitValueTexts: state.splitValueTexts,
    ).summaryLabel(_payerName(state));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Default split',
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _loading ? null : _save,
                child: const Text('Save'),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : BlocBuilder<AddExpenseBloc, AddExpenseState>(
                builder: (context, state) {
                  return ListView(
                    padding: EdgeInsets.symmetric(vertical: AppDimensions.md.h),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w),
                        child: Container(
                          padding: EdgeInsets.all(AppDimensions.md.r),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg.r),
                          ),
                          child: Text(
                            'New expenses you add to this group will default to this setting. '
                            'It is personal, not group-wide, and never changes past expenses.',
                            style: context.textTheme.bodySmall?.copyWith(height: 1.4),
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.md.h),
                      ListTile(
                        leading: Icon(Icons.payments_outlined, color: theme.colorScheme.onSurface),
                        title: const Text('Paid by'),
                        subtitle: Text(_payerName(state)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => PaidBySheet.show(context, _bloc),
                      ),
                      ListTile(
                        leading: Icon(Icons.dehaze_rounded, color: theme.colorScheme.onSurface),
                        title: const Text('Split'),
                        subtitle: Text(
                          _splitSummary(state),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          if (state.amount <= 0) {
                            _bloc.add(const AmountChanged('100'));
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: _bloc,
                                child: const AdjustSplitPage(),
                              ),
                            ),
                          );
                        },
                      ),
                      if (state.splitError != null)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w),
                          child: Text(
                            state.splitError!,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      SizedBox(height: AppDimensions.lg.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w),
                        child: Text(
                          'Preview uses ₹${GroupDefaultSplit.templateAmount.toStringAsFixed(0)} as a reference amount for exact splits.',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
