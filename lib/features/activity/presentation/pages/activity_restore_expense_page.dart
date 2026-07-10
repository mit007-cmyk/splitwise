import 'package:flutter/material.dart';
import '../../../../core/di/di.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../domain/entities/activity_event.dart';

class ActivityRestoreExpensePage extends StatefulWidget {
  final ActivityEvent event;
  final String currentUserId;

  const ActivityRestoreExpensePage({
    super.key,
    required this.event,
    required this.currentUserId,
  });

  @override
  State<ActivityRestoreExpensePage> createState() => _ActivityRestoreExpensePageState();
}

class _ActivityRestoreExpensePageState extends State<ActivityRestoreExpensePage> {
  final ExpenseRepository _repository = getIt<ExpenseRepository>();
  bool _restoring = false;

  Future<void> _restore() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    final Result<void> result = await _repository.restoreExpense(
      expenseId: widget.event.entityId,
      actorUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() => _restoring = false);
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense restored')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not restore this expense.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final before = widget.event.snapshotBefore ?? const <String, dynamic>{};
    final title = (before['title'] as String?) ??
        (widget.event.metadata['title'] as String?) ??
        'Deleted expense';
    final amount = (before['amount'] as num?)?.toDouble() ??
        (widget.event.metadata['amount'] as num?)?.toDouble() ??
        0.0;
    final symbol = (before['currencySymbol'] as String?) ??
        (widget.event.metadata['currencySymbol'] as String?) ??
        '';
    final groupName = (widget.event.metadata['groupName'] as String?) ?? 'group';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted expense'),
        actions: [
          TextButton(
            onPressed: _restoring ? null : _restore,
            child: _restoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Restore'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.textTheme.headlineSmall?.copyWith(
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$symbol${amount.toStringAsFixed(2)}',
              style: context.textTheme.headlineMedium?.copyWith(
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 8),
            Text('Group: $groupName'),
            const SizedBox(height: 8),
            Text(
              'Deleted on ${widget.event.performedAt}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

