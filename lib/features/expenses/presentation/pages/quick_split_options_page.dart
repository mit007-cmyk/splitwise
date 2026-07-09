import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../domain/entities/expense_participant.dart';
import '../../domain/entities/split_type.dart';
import '../bloc/add_expense_bloc.dart';
import '../bloc/add_expense_event.dart';
import '../bloc/add_expense_state.dart';
import 'adjust_split_page.dart';

/// "How was this expense split?" — a quick-pick screen for the common
/// 2-person cases (you paid / they paid, split equally or one side owes the
/// full amount), with a "More options" escape hatch to [AdjustSplitPage] for
/// full control over payers, participants and split type.
class QuickSplitOptionsPage extends StatelessWidget {
  const QuickSplitOptionsPage({super.key});

  static Future<void> show(BuildContext context, AddExpenseBloc bloc) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: bloc, child: const QuickSplitOptionsPage()),
      ),
    );
  }

  bool _isFullPercentageTo(AddExpenseState state, String owedInFullById) {
    if (state.splitType != SplitType.percentage) return false;
    final pct = double.tryParse((state.splitValueTexts[owedInFullById] ?? '').trim()) ?? -1;
    return (pct - 100).abs() < 0.1;
  }

  void _openMoreOptions(BuildContext context, AddExpenseBloc bloc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: bloc, child: const AdjustSplitPage()),
      ),
    );
  }

  void _applyPresetAndClose(
    BuildContext context,
    AddExpenseEvent event,
  ) {
    context.read<AddExpenseBloc>().add(event);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;
    final bloc = context.read<AddExpenseBloc>();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'How was this expense split?',
          style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<AddExpenseBloc, AddExpenseState>(
        builder: (context, state) {
          final you = ExpenseParticipant(id: state.currentUserId, name: 'You');
          final other = state.otherParticipant ??
              const ExpenseParticipant(id: '', name: 'them');

          final youPaidEqually = state.singlePayerId == state.currentUserId &&
              state.splitType == SplitType.equally;
          final youOwedFull =
              state.singlePayerId == state.currentUserId && _isFullPercentageTo(state, other.id);
          final otherPaidEqually =
              state.singlePayerId == other.id && state.splitType == SplitType.equally;
          final otherOwedFull =
              state.singlePayerId == other.id && _isFullPercentageTo(state, state.currentUserId);
          final amount = state.amount;
          final halfAmount = amount / 2;
          final showAmountDetails = amount > 0;

          return ListView(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.lg.h),
            children: [
              _buildOption(
                context,
                payer: you,
                other: other,
                label: 'You paid, split equally.',
                detailText: showAmountDetails
                    ? '${other.name} owes you ${state.currency.symbol}${halfAmount.toStringAsFixed(2)}'
                    : null,
                detailColor: appColors.positiveBalanceColor,
                selected: youPaidEqually,
                onTap: () => _applyPresetAndClose(
                  context,
                  QuickSplitPresetApplied(
                    payerId: state.currentUserId,
                    splitType: SplitType.equally,
                  ),
                ),
              ),
              _buildOption(
                context,
                payer: you,
                other: other,
                label: 'You are owed the full amount.',
                detailText: showAmountDetails
                    ? '${other.name} owes you ${state.currency.symbol}${amount.toStringAsFixed(2)}'
                    : null,
                detailColor: appColors.positiveBalanceColor,
                selected: youOwedFull,
                onTap: () => _applyPresetAndClose(
                  context,
                  QuickSplitPresetApplied(
                    payerId: state.currentUserId,
                    splitType: SplitType.percentage,
                    splitValueTexts: {state.currentUserId: '0', other.id: '100'},
                  ),
                ),
              ),
              _buildOption(
                context,
                payer: other,
                other: you,
                label: '${other.name} paid, split equally.',
                detailText: showAmountDetails
                    ? 'You owe ${other.name} ${state.currency.symbol}${halfAmount.toStringAsFixed(2)}'
                    : null,
                detailColor: appColors.negativeBalanceColor,
                selected: otherPaidEqually,
                onTap: () => _applyPresetAndClose(
                  context,
                  QuickSplitPresetApplied(
                    payerId: other.id,
                    splitType: SplitType.equally,
                  ),
                ),
              ),
              _buildOption(
                context,
                payer: other,
                other: you,
                label: '${other.name} is owed the full amount.',
                detailText: showAmountDetails
                    ? 'You owe ${other.name} ${state.currency.symbol}${amount.toStringAsFixed(2)}'
                    : null,
                detailColor: appColors.negativeBalanceColor,
                selected: otherOwedFull,
                onTap: () => _applyPresetAndClose(
                  context,
                  QuickSplitPresetApplied(
                    payerId: other.id,
                    splitType: SplitType.percentage,
                    splitValueTexts: {other.id: '0', state.currentUserId: '100'},
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.xxl.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.xxl.w),
                child: OutlinedButton(
                  onPressed: () => _openMoreOptions(context, bloc),
                  child: const Text('More options'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required ExpenseParticipant payer,
    required ExpenseParticipant other,
    required String label,
    String? detailText,
    Color? detailColor,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = context.colorScheme;

    return ListTile(
      leading: SizedBox(
        width: 52.w,
        height: 40.h,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: AvatarWidget(name: payer.name, imageUrl: payer.photoUrl, size: 32.w),
            ),
            Positioned(
              left: 18.w,
              child: AvatarWidget(name: other.name, imageUrl: other.photoUrl, size: 32.w),
            ),
          ],
        ),
      ),
      title: Text(label, style: context.textTheme.bodyLarge),
      subtitle: detailText == null
          ? null
          : Padding(
              padding: EdgeInsets.only(top: AppDimensions.xs.h),
              child: Text(
                detailText,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: detailColor ?? scheme.onSurfaceVariant,
                ),
              ),
            ),
      trailing: selected ? Icon(Icons.check, color: scheme.primary) : null,
      onTap: onTap,
    );
  }
}
