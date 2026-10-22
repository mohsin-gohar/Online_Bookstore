// End-to-end smoke tests: boot the real app widget against the mock backend
// and walk the main customer journey.
//
// These are the tests that catch "the app compiles but the first screen is
// blank" problems, which unit tests never see.
//
// Note: the app runs looping animations (the onboarding carousel auto-advances,
// loading placeholders shimmer), so `pumpAndSettle` never settles here. The
// tests advance the clock with explicit `pump` calls instead.

import 'package:bookstore_app/app.dart';
import 'package:bookstore_app/core/constants/app_strings.dart';
import 'package:bookstore_app/core/services/local_storage_service.dart';
import 'package:bookstore_app/data/mock/mock_transport.dart';
import 'package:bookstore_app/data/services/api_factory.dart';
import 'package:bookstore_app/data/services/token_storage_service.dart';
import 'package:bookstore_app/presentation/common_widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('boots to the onboarding flow on a fresh install', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildTestApp());

    // The splash screen shows the brand while the session resolves.
    expect(find.text(AppStrings.appName), findsOneWidget);

    await advancePastSplash(tester);

    // First launch lands on onboarding.
    expect(find.text(AppStrings.onboardingTitle1), findsOneWidget);
    expect(find.text(AppStrings.onboardingTitle2), findsNothing);
  });

  testWidgets('reaches the sign-in screen after onboarding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildTestApp());
    await advancePastSplash(tester);

    // Finish the onboarding carousel.
    await tester.tap(find.text(AppStrings.skip));
    await settle(tester);

    expect(find.text(AppStrings.welcomeBack), findsOneWidget);
    expect(find.text(AppStrings.email), findsOneWidget);
  });

  testWidgets('signs in with the demo account and lands on the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildTestApp());
    await advancePastSplash(tester);

    await tester.tap(find.text(AppStrings.skip));
    await settle(tester);

    await tester.enterText(
      fieldFor(tester, AppStrings.email),
      demoCustomerEmail,
    );
    await tester.enterText(
      fieldFor(tester, AppStrings.password),
      demoCustomerPassword,
    );
    await settle(tester);

    await tester.tap(find.text(AppStrings.login).last);
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 800));

    // The shell with the four bottom tabs is now visible.
    expect(find.text(AppStrings.home), findsWidgets);
    expect(find.text(AppStrings.catalog), findsWidgets);
  });
}

/// The text input belonging to the field labelled [label].
Finder fieldFor(WidgetTester tester, String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label),
    matching: find.byType(CustomTextField),
  ),
  matching: find.byType(TextFormField),
);

/// Advances the clock past the splash screen's minimum pause.
Future<void> advancePastSplash(WidgetTester tester) async {
  for (int i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Pumps a few frames so route transitions and animations can play out.
Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Boots [BookStoreApp] against a fresh mock backend and in-memory preferences.
Future<Widget> buildTestApp() async {
  final TokenStorageService tokens = TokenStorageService.inMemory();
  ApiFactory.overrideTokenStorage(tokens);
  ApiFactory.overrideTransport(createMockTransport(tokens));

  final LocalStorageService storage = await LocalStorageService.init();

  return BookStoreApp(localStorage: storage);
}
