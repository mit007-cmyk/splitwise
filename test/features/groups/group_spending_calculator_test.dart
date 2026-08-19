import 'package:flutter_test/flutter_test.dart';
import 'package:splitwise/features/expenses/domain/entities/expense.dart';
import 'package:splitwise/features/expenses/domain/entities/split_type.dart';
import 'package:splitwise/features/groups/domain/services/group_spending_calculator.dart';

Expense _expense({
  required String id,
  required double amount,
  required DateTime date,
  String category = 'General',
  String currencyCode = 'INR',
  String currencySymbol = '₹',
  Map<String, double> splits = const {'me': 0},
  bool isDeleted = false,
}) {
  return Expense(
    id: id,
    groupId: 'g1',
    title: id,
    category: category,
    amount: amount,
    currencyCode: currencyCode,
    currencySymbol: currencySymbol,
    date: date,
    paidBy: {'me': amount},
    splits: splits,
    splitType: SplitType.equally,
    participantIds: const ['me', 'friend'],
    createdBy: 'me',
    isDeleted: isDeleted,
  );
}

void main() {
  final august = DateTime(2026, 8, 14);
  final july = DateTime(2026, 7, 3);

  group('GroupSpendingCalculator', () {
    test('totals spending and your share for all time', () {
      final expenses = [
        _expense(
          id: 'e1',
          amount: 400,
          date: august,
          splits: const {'me': 133.34, 'friend': 266.66},
        ),
        _expense(
          id: 'e2',
          amount: 180,
          date: july,
          splits: const {'me': 60, 'friend': 120},
        ),
      ];

      final summary = GroupSpendingCalculator.summarize(
        expenses: expenses,
        currencyCode: 'INR',
        userId: 'me',
      );

      expect(summary.totalSpent, 580);
      expect(summary.yourShare, closeTo(193.34, 0.001));
      expect(summary.yourSharePercent, 33);
      expect(summary.currencySymbol, '₹');
    });

    test('scopes totals to a single month', () {
      final expenses = [
        _expense(
          id: 'e1',
          amount: 400,
          date: august,
          splits: const {'me': 133.34},
        ),
        _expense(id: 'e2', amount: 180, date: july, splits: const {'me': 60}),
      ];

      final summary = GroupSpendingCalculator.summarize(
        expenses: expenses,
        currencyCode: 'INR',
        userId: 'me',
        month: DateTime(2026, 8),
      );

      expect(summary.totalSpent, 400);
      expect(summary.yourShare, closeTo(133.34, 0.001));
    });

    test('ignores settlements and deleted expenses', () {
      final expenses = [
        _expense(id: 'e1', amount: 100, date: august, splits: const {'me': 50}),
        _expense(
          id: 'e2',
          amount: 500,
          date: august,
          category: 'Settlement',
          splits: const {'me': 500},
        ),
        _expense(
          id: 'e3',
          amount: 900,
          date: august,
          isDeleted: true,
          splits: const {'me': 900},
        ),
      ];

      final summary = GroupSpendingCalculator.summarize(
        expenses: expenses,
        currencyCode: 'INR',
        userId: 'me',
      );

      expect(summary.totalSpent, 100);
      expect(summary.yourShare, 50);
    });

    test('never mixes currencies', () {
      final expenses = [
        _expense(id: 'e1', amount: 100, date: august, splits: const {'me': 50}),
        _expense(
          id: 'e2',
          amount: 30,
          date: august,
          currencyCode: 'USD',
          currencySymbol: r'$',
          splits: const {'me': 10},
        ),
      ];

      expect(
        GroupSpendingCalculator.currencyCodes(expenses),
        ['INR', 'USD'],
      );

      final usd = GroupSpendingCalculator.summarize(
        expenses: expenses,
        currencyCode: 'USD',
        userId: 'me',
      );

      expect(usd.totalSpent, 30);
      expect(usd.yourShare, 10);
      expect(usd.currencySymbol, r'$');
    });

    test('lists the months that have spending, oldest first', () {
      final expenses = [
        _expense(id: 'e1', amount: 100, date: august, splits: const {'me': 50}),
        _expense(id: 'e2', amount: 100, date: july, splits: const {'me': 50}),
      ];

      expect(
        GroupSpendingCalculator.months(expenses, 'INR'),
        [DateTime(2026, 7), DateTime(2026, 8)],
      );
    });

    test('reports an empty summary when a month has no spending', () {
      final expenses = [
        _expense(id: 'e1', amount: 100, date: august, splits: const {'me': 50}),
      ];

      final summary = GroupSpendingCalculator.summarize(
        expenses: expenses,
        currencyCode: 'INR',
        userId: 'me',
        month: DateTime(2026, 6),
      );

      expect(summary.isEmpty, isTrue);
      expect(summary.yourSharePercent, 0);
      expect(summary.currencySymbol, '₹');
    });

    test('mine-only charts use the user share instead of the group amount', () {
      final expenses = [
        _expense(
          id: 'e1',
          amount: 300,
          date: august,
          category: 'Food & Dining',
          splits: const {'me': 100, 'friend': 200},
        ),
        _expense(
          id: 'e2',
          amount: 90,
          date: july,
          category: 'Travel',
          splits: const {'me': 0, 'friend': 90},
        ),
      ];

      final mine = GroupSpendingCalculator.summarize(
        expenses: expenses,
        currencyCode: 'INR',
        userId: 'me',
        forUserId: 'me',
      );
      expect(mine.totalSpent, 100);
      expect(mine.yourShare, 100);

      final overTime = GroupSpendingCalculator.spendingOverTime(
        expenses: expenses,
        currencyCode: 'INR',
        forUserId: 'me',
      );
      final augustPoint = overTime.firstWhere(
        (point) => point.date == DateTime(2026, 8),
      );
      expect(augustPoint.amount, 100);

      final categories = GroupSpendingCalculator.spendingByCategory(
        expenses: expenses,
        currencyCode: 'INR',
        forUserId: 'me',
      );
      expect(categories, hasLength(1));
      expect(categories.single.category, 'Food & Dining');
      expect(categories.single.amount, 100);
    });
  });
}
