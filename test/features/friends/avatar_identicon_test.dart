import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitwise/core/theme/app_colors.dart';
import 'package:splitwise/core/widgets/avatar_widget.dart';
import 'package:splitwise/core/widgets/geometric_identicon.dart';

void main() {
  testWidgets('shows a geometric identicon instead of initials', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AvatarWidget(name: 'Dhamo dhamaliyo', size: 56),
        ),
      ),
    );

    expect(find.byType(GeometricIdenticon), findsOneWidget);
    expect(find.text('DD'), findsNothing);
    expect(find.text('D'), findsNothing);
  });

  test('uses more than one colour family so people look different', () {
    expect(AppColors.identiconPalettes.length, greaterThanOrEqualTo(2));
  });
}
