// Phase 1 smoke tests for the onboarding screen.
//
// These widgets are intentionally backend-free so they can be rendered in a
// plain widget test without initialising a network client.

import 'package:bookstore_app/core/constants/app_strings.dart';
import 'package:bookstore_app/core/services/local_storage_service.dart';
import 'package:bookstore_app/presentation/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Onboarding shows the first slide and its actions', (
    WidgetTester tester,
  ) async {
    // In-memory SharedPreferences so LocalStorageService works in tests.
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.init();

    await tester.pumpWidget(
      Provider<LocalStorageService>.value(
        value: storage,
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );

    // First slide copy is visible.
    expect(find.text(AppStrings.onboardingTitle1), findsOneWidget);
    expect(find.text(AppStrings.next), findsOneWidget);
    expect(find.text(AppStrings.skip), findsOneWidget);

    // Tapping Next advances to the second slide.
    await tester.tap(find.text(AppStrings.next));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingTitle2), findsOneWidget);
  });
}
