import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitwise/features/groups/presentation/widgets/group_spending_chart.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, inner) => MaterialApp(
        home: Scaffold(body: Padding(padding: const EdgeInsets.all(24), child: inner)),
      ),
      child: child,
    ),
  );
}

void main() {
  testWidgets('donut shows the total immediately and settles after the share '
      'arc sweeps in', (tester) async {
    await _pump(
      tester,
      const Center(
        child: GroupSpendingDonut(
          totalSpent: 580,
          yourShare: 193.34,
          centerLabel: 'Total',
          currencySymbol: '₹',
        ),
      ),
    );

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('₹580.00'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('₹580.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bars render one labelled column per month and report taps', (
    tester,
  ) async {
    var selected = -1;

    await _pump(
      tester,
      GroupSpendingBars(
        onSelect: (index) => selected = index,
        bars: const [
          GroupSpendingBar(
            label: 'JUN',
            totalSpent: 0,
            yourShare: 0,
            isSelected: false,
          ),
          GroupSpendingBar(
            label: 'JUL',
            totalSpent: 0,
            yourShare: 0,
            isSelected: false,
          ),
          GroupSpendingBar(
            label: 'AUG',
            totalSpent: 580,
            yourShare: 193.34,
            isSelected: true,
          ),
        ],
      ),
    );

    expect(find.text('JUN'), findsOneWidget);
    expect(find.text('JUL'), findsOneWidget);
    expect(find.text('AUG'), findsOneWidget);

    await tester.tap(find.byType(GestureDetector).first);
    expect(selected, 0);
  });

  testWidgets('bars survive a group with no spending at all', (tester) async {
    await _pump(
      tester,
      GroupSpendingBars(
        onSelect: (_) {},
        bars: const [
          GroupSpendingBar(
            label: 'JUN',
            totalSpent: 0,
            yourShare: 0,
            isSelected: true,
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
