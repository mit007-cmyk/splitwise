import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitwise/features/groups/presentation/widgets/spending_terms_sheet.dart';

void main() {
  testWidgets('opens from a "?" and closes again', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(home: child),
        child: Scaffold(
          body: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => SpendingTermsSheet.show(context),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.text('What do these terms mean?'), findsOneWidget);
    expect(find.textContaining('Total spent'), findsOneWidget);
    expect(find.textContaining('Your share'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('What do these terms mean?'), findsNothing);
  });
}
