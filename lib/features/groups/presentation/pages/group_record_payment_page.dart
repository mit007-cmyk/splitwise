import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/entities/default_categories.dart';
import '../../../expenses/domain/entities/split_type.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../home/domain/entities/balance_summary.dart';
import '../../../home/domain/entities/group_summary.dart';

class GroupRecordPaymentPage extends StatefulWidget {
  final String groupId;
  final String currentUserId;
  final MemberBalance balance;

  const GroupRecordPaymentPage({
    super.key,
    required this.groupId,
    required this.currentUserId,
    required this.balance,
  });

  @override
  State<GroupRecordPaymentPage> createState() => _GroupRecordPaymentPageState();
}

class _GroupRecordPaymentPageState extends State<GroupRecordPaymentPage> {
  final ExpenseRepository _expenseRepository = getIt<ExpenseRepository>();
  late final TextEditingController _amountController;
  final ValueNotifier<bool> _isSaving = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.balance.amount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _isSaving.dispose();
    super.dispose();
  }

  Future<void> _recordPayment() async {
    if (_isSaving.value) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      AppToast.show(context, 'Enter a valid amount', type: ToastType.warning);
      return;
    }

    _isSaving.value = true;

    final otherId = widget.balance.userId.trim();
    if (otherId.isEmpty || widget.currentUserId.trim().isEmpty) {
      _isSaving.value = false;
      if (!mounted) return;
      AppToast.show(context, 'This balance cannot be settled. Please refresh and try again.', type: ToastType.error);
      return;
    }
    final youOwe = widget.balance.type == BalanceType.owe;
    final paidBy = youOwe ? <String, double>{widget.currentUserId: amount} : <String, double>{otherId: amount};
    final splits = youOwe ? <String, double>{otherId: amount} : <String, double>{widget.currentUserId: amount};
    final participantIds = <String>{widget.currentUserId.trim(), otherId}.where((id) => id.isNotEmpty).toList();

    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      groupId: widget.groupId,
      title: 'Settlement',
      category: DefaultCategories.settlement.name,
      categoryId: DefaultCategories.settlement.id,
      categorySource: DefaultCategories.settlement.source,
      categoryIcon: DefaultCategories.settlement.iconKey,
      amount: amount,
      currencyCode: widget.balance.currencyCode,
      currencySymbol: widget.balance.currencySymbol,
      date: DateTime.now(),
      notes: 'Settlement with ${widget.balance.userName}',
      paidBy: paidBy,
      splits: splits,
      splitType: SplitType.unequally,
      participantIds: participantIds,
      createdBy: widget.currentUserId,
    );

    final Result<void> result = await _expenseRepository.createExpense(expense);
    _isSaving.value = false;

    if (!mounted) return;
    if (result.isSuccess) {
      AppToast.show(context, 'Payment recorded', type: ToastType.success);
      Navigator.of(context).pop(true);
    } else {
      AppToast.show(context, 'Could not record payment. Please try again.', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final youOwe = widget.balance.type == BalanceType.owe;
    final payerName = youOwe ? 'You' : widget.balance.userName;
    final receiverName = youOwe ? widget.balance.userName : 'You';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          'Record a payment',
          style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppDimensions.lg.w),
        child: Column(
          children: [
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AvatarWidget(name: payerName, size: 68.w),
                SizedBox(width: AppDimensions.md.w),
                Icon(Icons.arrow_forward, size: 30.r, color: context.colorScheme.onSurfaceVariant),
                SizedBox(width: AppDimensions.md.w),
                AvatarWidget(name: receiverName, size: 68.w),
              ],
            ),
            SizedBox(height: AppDimensions.lg.h),
            Text(
              youOwe ? 'You paid ${widget.balance.userName}' : '${widget.balance.userName} paid you',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: AppDimensions.lg.h),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: context.textTheme.displaySmall,
              decoration: InputDecoration(
                prefixText: widget.balance.currencySymbol,
                border: InputBorder.none,
              ),
            ),
            SizedBox(height: AppDimensions.lg.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.md.w,
                vertical: AppDimensions.md.h,
              ),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18.r,
                    color: context.colorScheme.primary,
                  ),
                  SizedBox(width: AppDimensions.sm.w),
                  Expanded(
                    child: Text(
                      'You are recording a payment that happened outside '
                      'Splitwise. No money will be moved.',
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ValueListenableBuilder<bool>(
              valueListenable: _isSaving,
              builder: (context, isSaving, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _recordPayment,
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Record a payment'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

