import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/features/patient_file/presentation/widgets/before_after_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BeforeAfterSlider renders drag handle and labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: BeforeAfterSlider(
              beforeImageUrl: '',
              afterImageUrl: '',
              beforeLabel: 'Initial',
              afterLabel: 'Final',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BeforeAfterSlider), findsOneWidget);
    expect(find.text('Initial'), findsOneWidget);
    expect(find.text('Final'), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);

    // Test dragging the slider
    await tester.drag(find.byType(BeforeAfterSlider), const Offset(-50, 0));
    await tester.pumpAndSettle();
  });
}
