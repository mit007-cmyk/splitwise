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

/// Renders the per-participant rows for whichever [SplitType] is active,
/// plus the running-total footer. Every keystroke dispatches a bloc event —
/// there is no local widget state driving the numbers on screen.
class SplitEditor extends StatelessWidget {
  final AddExpenseState state;

  const SplitEditor({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final participants = state.members;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.sm.h),
            itemCount: participants.length,
            itemBuilder: (context, index) => _buildRow(context, participants[index]),
          ),
        ),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildRow(BuildContext context, ExpenseParticipant participant) {
    switch (state.splitType) {
      case SplitType.equally:
        return _EquallyRow(
          key: ValueKey('equally_${participant.id}'),
          participant: participant,
          state: state,
        );
      case SplitType.unequally:
        return _AmountInputRow(
          key: ValueKey('unequal_${participant.id}'),
          participant: participant,
          state: state,
          currencySymbol: state.currency.symbol,
        );
      case SplitType.percentage:
        return _PercentageRow(
          key: ValueKey('pct_${participant.id}'),
          participant: participant,
          state: state,
        );
      case SplitType.shares:
        return _SharesRow(
          key: ValueKey('shares_${participant.id}'),
          participant: participant,
          state: state,
        );
      case SplitType.adjustment:
        return _AdjustmentRow(
          key: ValueKey('adj_${participant.id}'),
          participant: participant,
          state: state,
        );
    }
  }

  Widget _buildFooter(BuildContext context) {
    final scheme = context.colorScheme;
    final splits = state.computedSplits;
    final total = splits.values.fold(0.0, (a, b) => a + b);

    String text;
    switch (state.splitType) {
      case SplitType.equally:
        final perPerson = state.selectedParticipantIds.isEmpty
            ? 0.0
            : state.amount / state.selectedParticipantIds.length;
        text =
            '${state.currency.symbol}${perPerson.toStringAsFixed(2)}/person (${state.selectedParticipantIds.length} people)';
        break;
      case SplitType.unequally:
        text =
            '${state.currency.symbol}${total.toStringAsFixed(2)} of ${state.currency.symbol}${state.amount.toStringAsFixed(2)}';
        break;
      case SplitType.percentage:
        final pctTotal = state.selectedParticipantIds.fold<double>(
          0.0,
          (sum, id) => sum + (double.tryParse(state.splitValueTexts[id] ?? '') ?? 0.0),
        );
        text = '${pctTotal.toStringAsFixed(0)}% of 100%';
        break;
      case SplitType.shares:
        final totalShares = state.selectedParticipantIds.fold<int>(
          0,
          (sum, id) => sum + (int.tryParse(state.splitValueTexts[id] ?? '') ?? 0),
        );
        text = '$totalShares total shares';
        break;
      case SplitType.adjustment:
        text =
            '${state.currency.symbol}${total.toStringAsFixed(2)} of ${state.currency.symbol}${state.amount.toStringAsFixed(2)}';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w, vertical: AppDimensions.md.h),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(
              color: state.splitError == null ? scheme.onSurfaceVariant : scheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EquallyRow extends StatelessWidget {
  final ExpenseParticipant participant;
  final AddExpenseState state;

  const _EquallyRow({super.key, required this.participant, required this.state});

  @override
  Widget build(BuildContext context) {
    final isSelected = state.selectedParticipantIds.contains(participant.id);
    final splits = state.computedSplits;

    return ListTile(
      leading: AvatarWidget(name: participant.name, imageUrl: participant.photoUrl, size: 40.w),
      title: Text(participant.name, style: context.textTheme.bodyLarge),
      subtitle: isSelected
          ? Text('${state.currency.symbol}${(splits[participant.id] ?? 0).toStringAsFixed(2)}')
          : null,
      trailing: Checkbox(
        value: isSelected,
        onChanged: (_) =>
            context.read<AddExpenseBloc>().add(ParticipantToggled(participant.id)),
      ),
      onTap: () => context.read<AddExpenseBloc>().add(ParticipantToggled(participant.id)),
    );
  }
}

class _AmountInputRow extends StatefulWidget {
  final ExpenseParticipant participant;
  final AddExpenseState state;
  final String currencySymbol;

  const _AmountInputRow({
    super.key,
    required this.participant,
    required this.state,
    required this.currencySymbol,
  });

  @override
  State<_AmountInputRow> createState() => _AmountInputRowState();
}

class _AmountInputRowState extends State<_AmountInputRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.splitValueTexts[widget.participant.id] ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.state.selectedParticipantIds.contains(widget.participant.id)) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: AvatarWidget(
        name: widget.participant.name,
        imageUrl: widget.participant.photoUrl,
        size: 40.w,
      ),
      title: Text(widget.participant.name, style: context.textTheme.bodyLarge),
      trailing: SizedBox(
        width: 100.w,
        child: TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.end,
          decoration: InputDecoration(prefixText: widget.currencySymbol, isDense: true),
          onChanged: (value) => context.read<AddExpenseBloc>().add(
                SplitValueChanged(userId: widget.participant.id, valueText: value),
              ),
        ),
      ),
    );
  }
}

class _PercentageRow extends StatefulWidget {
  final ExpenseParticipant participant;
  final AddExpenseState state;

  const _PercentageRow({super.key, required this.participant, required this.state});

  @override
  State<_PercentageRow> createState() => _PercentageRowState();
}

class _PercentageRowState extends State<_PercentageRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.splitValueTexts[widget.participant.id] ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.state.selectedParticipantIds.contains(widget.participant.id)) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: AvatarWidget(
        name: widget.participant.name,
        imageUrl: widget.participant.photoUrl,
        size: 40.w,
      ),
      title: Text(widget.participant.name, style: context.textTheme.bodyLarge),
      trailing: SizedBox(
        width: 80.w,
        child: TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.end,
          decoration: const InputDecoration(suffixText: '%', isDense: true),
          onChanged: (value) => context.read<AddExpenseBloc>().add(
                SplitValueChanged(userId: widget.participant.id, valueText: value),
              ),
        ),
      ),
    );
  }
}

class _SharesRow extends StatelessWidget {
  final ExpenseParticipant participant;
  final AddExpenseState state;

  const _SharesRow({super.key, required this.participant, required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.selectedParticipantIds.contains(participant.id)) {
      return const SizedBox.shrink();
    }

    final shares = int.tryParse(state.splitValueTexts[participant.id] ?? '') ?? 0;

    return ListTile(
      leading: AvatarWidget(name: participant.name, imageUrl: participant.photoUrl, size: 40.w),
      title: Text(participant.name, style: context.textTheme.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: shares > 0
                ? () => context.read<AddExpenseBloc>().add(
                      SplitValueChanged(userId: participant.id, valueText: '${shares - 1}'),
                    )
                : null,
          ),
          Text('$shares', style: context.textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.read<AddExpenseBloc>().add(
                  SplitValueChanged(userId: participant.id, valueText: '${shares + 1}'),
                ),
          ),
        ],
      ),
    );
  }
}

class _AdjustmentRow extends StatefulWidget {
  final ExpenseParticipant participant;
  final AddExpenseState state;

  const _AdjustmentRow({super.key, required this.participant, required this.state});

  @override
  State<_AdjustmentRow> createState() => _AdjustmentRowState();
}

class _AdjustmentRowState extends State<_AdjustmentRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.splitValueTexts[widget.participant.id] ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.state.selectedParticipantIds.contains(widget.participant.id)) {
      return const SizedBox.shrink();
    }

    final splits = widget.state.computedSplits;

    return ListTile(
      leading: AvatarWidget(
        name: widget.participant.name,
        imageUrl: widget.participant.photoUrl,
        size: 40.w,
      ),
      title: Text(widget.participant.name, style: context.textTheme.bodyLarge),
      subtitle: Text(
        '${widget.state.currency.symbol}${(splits[widget.participant.id] ?? 0).toStringAsFixed(2)}',
      ),
      trailing: SizedBox(
        width: 100.w,
        child: TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          textAlign: TextAlign.end,
          decoration: InputDecoration(prefixText: '+${widget.state.currency.symbol}', isDense: true),
          onChanged: (value) => context.read<AddExpenseBloc>().add(
                SplitValueChanged(userId: widget.participant.id, valueText: value),
              ),
        ),
      ),
    );
  }
}
