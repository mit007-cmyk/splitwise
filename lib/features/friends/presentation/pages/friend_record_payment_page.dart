import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/entities/split_type.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';

/// A friend-level "Record a payment" page.
///
/// Mirrors [GroupRecordPaymentPage] but works for friend-to-friend settlements
/// that may span multiple shared groups (or no group at all). The settlement
/// expense is recorded against [groupId] when provided, otherwise without one.
class FriendRecordPaymentPage extends StatefulWidget {
  final String currentUserId;
  final String friendId;
  final String friendName;
  final String? friendEmail;
  final String? friendPhotoUrl;

  /// Positive  → you are owed (friend owes you).
  /// Negative  → you owe the friend.
  final double balance;

  /// Optional: the sole shared group to record the settlement against.
  final String? groupId;

  const FriendRecordPaymentPage({
    super.key,
    required this.currentUserId,
    required this.friendId,
    required this.friendName,
    required this.balance,
    this.friendEmail,
    this.friendPhotoUrl,
    this.groupId,
  });

  @override
  State<FriendRecordPaymentPage> createState() =>
      _FriendRecordPaymentPageState();
}

class _FriendRecordPaymentPageState extends State<FriendRecordPaymentPage> {
  final ExpenseRepository _expenseRepository = getIt<ExpenseRepository>();
  late final TextEditingController _amountController;
  final ValueNotifier<bool> _isSaving = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.balance.abs().toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _isSaving.dispose();
    super.dispose();
  }

  /// true  → you are owed (friend owes you → you are "receiver").
  bool get _friendOwesYou => widget.balance > 0;

  Future<void> _recordPayment() async {
    if (_isSaving.value) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      if (!mounted) return;
      AppToast.show(context, 'Enter a valid amount', type: ToastType.warning);
      return;
    }

    final groupId = widget.groupId?.trim() ?? '';
    if (groupId.isEmpty) {
      if (!mounted) return;
      AppToast.show(
        context,
        'No shared group found to record this payment.',
        type: ToastType.error,
      );
      return;
    }

    if (widget.currentUserId.trim().isEmpty || widget.friendId.trim().isEmpty) {
      if (!mounted) return;
      AppToast.show(
        context,
        'This balance cannot be settled. Please refresh and try again.',
        type: ToastType.error,
      );
      return;
    }

    _isSaving.value = true;

    // payer → the person sending the money.
    // splits entry → the person receiving (owed the money).
    final paidBy = _friendOwesYou
        ? <String, double>{widget.friendId: amount}
        : <String, double>{widget.currentUserId: amount};
    final splits = _friendOwesYou
        ? <String, double>{widget.currentUserId: amount}
        : <String, double>{widget.friendId: amount};

    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      groupId: groupId,
      title: 'Settlement',
      category: 'Settlement',
      amount: amount,
      currencyCode: 'INR',
      currencySymbol: '₹',
      date: DateTime.now(),
      notes: 'Settlement with ${widget.friendName}',
      paidBy: paidBy,
      splits: splits,
      splitType: SplitType.unequally,
      participantIds: [widget.currentUserId, widget.friendId],
      createdBy: widget.currentUserId,
    );

    final Result<void> result = await _expenseRepository.createExpense(expense);
    if (!mounted) return;
    _isSaving.value = false;

    if (result.isSuccess) {
      AppToast.show(context, 'Payment recorded', type: ToastType.success);
      Navigator.of(context).pop(true);
    } else {
      AppToast.show(context, 'Could not record payment. Please try again.', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payerName = _friendOwesYou ? widget.friendName : 'You';
    final receiverName = _friendOwesYou ? 'You' : widget.friendName;
    final payerPhotoUrl = _friendOwesYou ? widget.friendPhotoUrl : null;
    final receiverPhotoUrl = _friendOwesYou ? null : widget.friendPhotoUrl;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          'Record a payment',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppDimensions.lg.w),
        child: Column(
          children: [
            const Spacer(),

            // ── Avatars with arrow ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AvatarWidget(
                  name: payerName,
                  imageUrl: payerPhotoUrl,
                  size: 68.w,
                ),
                SizedBox(width: AppDimensions.md.w),
                Icon(
                  Icons.arrow_forward,
                  size: 30.r,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: AppDimensions.md.w),
                AvatarWidget(
                  name: receiverName,
                  imageUrl: receiverPhotoUrl,
                  size: 68.w,
                ),
              ],
            ),

            SizedBox(height: AppDimensions.lg.h),

            // ── Direction label ─────────────────────────────────────────────
            Text(
              _friendOwesYou
                  ? '${widget.friendName} paid you'
                  : 'You paid ${widget.friendName}',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),

            // ── Friend e-mail sub-label (when available) ────────────────────
            if (widget.friendEmail != null && widget.friendEmail!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  widget.friendEmail!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            SizedBox(height: AppDimensions.lg.h),

            // ── Editable amount ─────────────────────────────────────────────
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: context.textTheme.displaySmall,
              decoration: const InputDecoration(
                prefixText: '₹',
                border: InputBorder.none,
              ),
            ),

            SizedBox(height: AppDimensions.lg.h),

            // ── Info card ───────────────────────────────────────────────────
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

            // ── CTA button ──────────────────────────────────────────────────
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
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
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
