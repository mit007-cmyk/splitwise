import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../friends/domain/repositories/friends_repository.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/split_type.dart';
import '../../domain/repositories/expense_repository.dart';
import '../bloc/add_expense_bloc.dart';
import '../bloc/add_expense_event.dart';
import '../bloc/add_expense_state.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/currency_picker_sheet.dart';
import '../widgets/group_picker_sheet.dart';
import '../widgets/paid_by_sheet.dart';
import 'adjust_split_page.dart';
import 'quick_split_options_page.dart';

class AddExpensePage extends StatefulWidget {
  final String? groupId;

  /// When set, opens the simplified "friend mode" flow: this friend is
  /// pre-selected as the only other participant/payer instead of asking the
  /// user to choose a group first.
  final String? friendId;
  final Expense? existingExpense;

  const AddExpensePage({
    super.key,
    this.groupId,
    this.friendId,
    this.existingExpense,
  });

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  bool _didPrefill = false;
  late final AddExpenseBloc _bloc;
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

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
      currentUserId: currentUserId,
      currentUserName: currentUserName,
    )..add(
        InitAddExpense(
          groupId: widget.groupId,
          friendId: widget.friendId,
          existingExpense: widget.existingExpense,
        ),
      );

    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _bloc.close();
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      _bloc.add(DateChanged(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<AddExpenseBloc, AddExpenseState>(
        listenWhen: (previous, current) =>
            previous.status != current.status || previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.status == AddExpenseStatus.success) {
            final message = switch (state.lastAction) {
              AddExpenseAction.delete => 'Expense deleted!',
              AddExpenseAction.save =>
                state.isEditMode ? 'Expense updated!' : 'Expense added!',
              AddExpenseAction.none => 'Saved successfully!',
            };
            AppToast.show(context, message, type: ToastType.success);
            context.pop(true);
          } else if (state.errorMessage != null) {
            AppToast.show(context, state.errorMessage!, type: ToastType.error);
          }
        },
        child: Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(false),
            ),
            title: Text(
              stateTitle(widget.existingExpense != null),
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            centerTitle: false,
            actions: [
              BlocBuilder<AddExpenseBloc, AddExpenseState>(
                buildWhen: (previous, current) =>
                    previous.canSave != current.canSave || previous.status != current.status,
                builder: (context, state) {
                  if (state.status == AddExpenseStatus.saving) {
                    return Padding(
                      padding: EdgeInsets.all(AppDimensions.md.w),
                      child: SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return IconButton(
                    icon: Icon(Icons.check, color: state.canSave ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    onPressed: state.canSave
                        ? () => context.read<AddExpenseBloc>().add(const SaveExpenseRequested())
                        : null,
                  );
                },
              ),
              BlocBuilder<AddExpenseBloc, AddExpenseState>(
                buildWhen: (previous, current) =>
                    previous.isEditMode != current.isEditMode ||
                    previous.canModifyExpense != current.canModifyExpense ||
                    previous.status != current.status,
                builder: (context, state) {
                  if (!state.isEditMode || !state.canModifyExpense) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: Icon(Icons.delete_outline, color: scheme.error),
                    onPressed: state.status == AddExpenseStatus.saving
                        ? null
                        : () => _confirmDelete(context),
                  );
                },
              ),
              SizedBox(width: AppDimensions.sm.w),
            ],
          ),
          body: BlocBuilder<AddExpenseBloc, AddExpenseState>(
            builder: (context, state) {
              if (state.status == AddExpenseStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!_didPrefill &&
                  (state.isEditMode ||
                      state.title.isNotEmpty ||
                      state.amountText.isNotEmpty ||
                      state.notes.isNotEmpty)) {
                _didPrefill = true;
                _titleController.text = state.title;
                _amountController.text = state.amountText;
                _notesController.text = state.notes;
              }
              return _buildForm(context, state);
            },
          ),
        ),
      ),
    );
  }

  String stateTitle(bool isEditing) => isEditing ? 'Edit expense' : 'Add expense';

  Widget _buildForm(BuildContext context, AddExpenseState state) {
    final scheme = context.colorScheme;

    return ListView(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.md.h),
      children: [
        state.isDirectExpense ? _buildFriendChip(context, state) : _buildGroupChip(context, state),
        const Divider(height: 1),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w, vertical: AppDimensions.lg.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: scheme.surfaceContainerHighest,
                child: Icon(Icons.receipt_long_outlined, color: scheme.onSurfaceVariant),
              ),
              SizedBox(width: AppDimensions.md.w),
              Expanded(
                child: TextField(
                  controller: _titleController,
                  style: context.textTheme.titleMedium,
                  decoration: const InputDecoration(
                    hintText: 'Enter a description',
                    border: UnderlineInputBorder(),
                  ),
                  onChanged: (value) => context.read<AddExpenseBloc>().add(TitleChanged(value)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 48.w),
              GestureDetector(
                onTap: () => CurrencyPickerSheet.show(context, _bloc),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: AppDimensions.md.w, vertical: AppDimensions.sm.h),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd.r),
                  ),
                  child: Text(state.currency.symbol, style: context.textTheme.titleLarge),
                ),
              ),
              SizedBox(width: AppDimensions.md.w),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    border: UnderlineInputBorder(),
                  ),
                  onChanged: (value) => context.read<AddExpenseBloc>().add(AmountChanged(value)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppDimensions.lg.h),
        state.otherParticipant != null
            ? _buildQuickSplitButton(context, state)
            : _buildPaidAndSplitRow(context, state),
        const Divider(height: 1),
        ListTile(
          leading: Icon(Icons.category_outlined, color: scheme.onSurface),
          title: const Text('Category'),
          trailing: Text(state.category, style: context.textTheme.bodyMedium),
          onTap: () => CategoryPickerSheet.show(context, _bloc),
        ),
        ListTile(
          leading: Icon(Icons.calendar_today_outlined, color: scheme.onSurface),
          title: const Text('Date'),
          trailing: Text(DateFormat('d MMM yyyy').format(state.date), style: context.textTheme.bodyMedium),
          onTap: () => _pickDate(context, state.date),
        ),
        if (state.isDirectExpense)
          ListTile(
            leading: Icon(Icons.groups_outlined, color: scheme.onSurface),
            title: const Text('Choose group'),
            subtitle: const Text('Optionally attach this to a real group instead'),
            onTap: () => GroupPickerSheet.show(context, _bloc),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w, vertical: AppDimensions.sm.h),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Add any notes about this expense',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => context.read<AddExpenseBloc>().add(NotesChanged(value)),
          ),
        ),
        if (state.isEditMode && !state.canModifyExpense)
          _buildInlineError(context, 'Only the creator can edit or delete this expense.'),
        if (state.amountError != null && state.amountText.isNotEmpty)
          _buildInlineError(context, state.amountError!),
        if (state.participantsError != null)
          _buildInlineError(context, state.participantsError!),
        SizedBox(height: AppDimensions.xxl.h),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<AddExpenseBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text(
          'This will remove this expense from balances for all participants.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      bloc.add(const DeleteExpenseRequested());
    }
  }

  Widget _buildInlineError(BuildContext context, String message) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w, vertical: AppDimensions.xs.h),
      child: Text(
        message,
        style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.error),
      ),
    );
  }

  Widget _buildGroupChip(BuildContext context, AddExpenseState state) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w, vertical: AppDimensions.sm.h),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('With you and: ', style: context.textTheme.bodyMedium),
          GestureDetector(
            onTap: () => GroupPickerSheet.show(context, _bloc),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.md.w, vertical: AppDimensions.xs.h),
              decoration: BoxDecoration(
                color: state.groupId == null
                    ? scheme.errorContainer.withValues(alpha: 0.4)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppDimensions.radiusCircular),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.groupId == null ? 'Choose a group' : 'All of ${state.groupName}',
                    style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Icon(Icons.arrow_drop_down, size: 18.r, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendChip(BuildContext context, AddExpenseState state) {
    final friend = state.otherParticipant;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w, vertical: AppDimensions.sm.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('With you and: ', style: context.textTheme.bodyMedium),
          if (friend != null) ...[
            AvatarWidget(name: friend.name, imageUrl: friend.photoUrl, size: 22.w),
            SizedBox(width: AppDimensions.xs.w),
            Text(
              friend.name,
              style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickSplitButton(BuildContext context, AddExpenseState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w, vertical: AppDimensions.sm.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(
          onPressed: () => QuickSplitOptionsPage.show(context, _bloc),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.sm.w),
            child: Text(_quickSplitSummary(state)),
          ),
        ),
      ),
    );
  }

  String _quickSplitSummary(AddExpenseState state) {
    final other = state.otherParticipant;
    final payerIsYou = state.singlePayerId == state.currentUserId;
    final payerName = payerIsYou ? 'you' : (other?.name.toLowerCase() ?? 'someone');

    if (other != null && state.splitType == SplitType.percentage) {
      final owedFullId = payerIsYou ? other.id : state.currentUserId;
      final pct = double.tryParse((state.splitValueTexts[owedFullId] ?? '').trim()) ?? -1;
      if ((pct - 100).abs() < 0.1) {
        return payerIsYou ? 'You are owed the full amount.' : '${other.name} is owed the full amount.';
      }
    }
    return 'Paid by $payerName and split ${state.splitType.label.toLowerCase()}.';
  }

  String _resolvePayerName(AddExpenseState state) {
    if (state.isMultiplePayers) return 'multiple people';
    for (final member in state.members) {
      if (member.id == state.singlePayerId) return member.name.toLowerCase();
    }
    return 'someone';
  }

  Widget _buildPaidAndSplitRow(BuildContext context, AddExpenseState state) {
    final payerName = _resolvePayerName(state);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w, vertical: AppDimensions.sm.h),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Paid by ', style: context.textTheme.bodyMedium),
          GestureDetector(
            onTap: () => PaidBySheet.show(context, _bloc),
            child: Text(
              payerName,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          Text(' and split ', style: context.textTheme.bodyMedium),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(value: _bloc, child: const AdjustSplitPage()),
              ),
            ),
            child: Text(
              state.splitType.label.toLowerCase(),
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}