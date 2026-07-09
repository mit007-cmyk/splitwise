import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../domain/services/split_calculator.dart';
import '../bloc/add_expense_bloc.dart';
import '../bloc/add_expense_event.dart';
import '../bloc/add_expense_state.dart';

/// "Who paid?" bottom sheet. Defaults to a single-payer radio list; the
/// "Multiple people" tile flips the same sheet into an amount-per-person
/// entry screen, all driven by [AddExpenseBloc].
class PaidBySheet extends StatelessWidget {
  const PaidBySheet({super.key});

  static Future<void> show(BuildContext context, AddExpenseBloc bloc) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl.r)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: const PaidBySheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return BlocBuilder<AddExpenseBloc, AddExpenseState>(
          builder: (context, state) {
            return state.isMultiplePayers
                ? _MultiplePayersView(state: state, scrollController: scrollController)
                : _SinglePayerView(state: state, scrollController: scrollController);
          },
        );
      },
    );
  }
}

class _SinglePayerView extends StatelessWidget {
  final AddExpenseState state;
  final ScrollController scrollController;

  const _SinglePayerView({required this.state, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.lg.w,
            AppDimensions.md.h,
            AppDimensions.lg.w,
            AppDimensions.sm.h,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Who paid?',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            children: [
              ...state.members.map(
                (member) => ListTile(
                  leading: AvatarWidget(name: member.name, imageUrl: member.photoUrl, size: 40.w),
                  title: Text(member.name),
                  trailing: state.singlePayerId == member.id
                      ? Icon(Icons.check, color: context.colorScheme.primary)
                      : null,
                  onTap: () {
                    context.read<AddExpenseBloc>().add(SinglePayerSelected(member.id));
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(
                  'Multiple people',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => context.read<AddExpenseBloc>().add(const MultiplePayersToggled(true)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MultiplePayersView extends StatelessWidget {
  final AddExpenseState state;
  final ScrollController scrollController;

  const _MultiplePayersView({required this.state, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final paid = state.computedPaidBy;
    final total = SplitCalculator.sumOf(paid);
    final remaining = state.amount - total;
    final scheme = context.colorScheme;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.lg.w,
            AppDimensions.md.h,
            AppDimensions.lg.w,
            AppDimensions.sm.h,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.read<AddExpenseBloc>().add(const MultiplePayersToggled(false)),
              ),
              Expanded(
                child: Text(
                  'Enter paid amounts',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.check, color: scheme.primary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: state.members.length,
            itemBuilder: (context, index) => _PayerAmountRow(
              key: ValueKey('payer_${state.members[index].id}'),
              memberId: state.members[index].id,
              memberName: state.members[index].name,
              memberPhotoUrl: state.members[index].photoUrl,
              currencySymbol: state.currency.symbol,
              initialText: state.payerAmountTexts[state.members[index].id] ?? '',
            ),
          ),
        ),
        Container(
          padding:
              EdgeInsets.symmetric(horizontal: AppDimensions.lg.w, vertical: AppDimensions.md.h),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3))),
          ),
          child: Text(
            '${state.currency.symbol}${total.toStringAsFixed(2)} of ${state.currency.symbol}${state.amount.toStringAsFixed(2)}'
            '${remaining.abs() > 0.01 ? '  ·  ${state.currency.symbol}${remaining.toStringAsFixed(2)} left' : ''}',
            style: context.textTheme.bodyMedium?.copyWith(
              color: state.isPaidValid ? scheme.onSurfaceVariant : scheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PayerAmountRow extends StatefulWidget {
  final String memberId;
  final String memberName;
  final String? memberPhotoUrl;
  final String currencySymbol;
  final String initialText;

  const _PayerAmountRow({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.memberPhotoUrl,
    required this.currencySymbol,
    required this.initialText,
  });

  @override
  State<_PayerAmountRow> createState() => _PayerAmountRowState();
}

class _PayerAmountRowState extends State<_PayerAmountRow> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AvatarWidget(name: widget.memberName, imageUrl: widget.memberPhotoUrl, size: 40.w),
      title: Text(widget.memberName),
      trailing: SizedBox(
        width: 110.w,
        child: TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.end,
          decoration: InputDecoration(prefixText: widget.currencySymbol, isDense: true),
          onChanged: (value) => context.read<AddExpenseBloc>().add(
                PayerAmountChanged(userId: widget.memberId, amountText: value),
              ),
        ),
      ),
    );
  }
}
