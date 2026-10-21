/// Navigation helpers built on top of GoRouter.
///
/// The router itself is defined in `app_pages.dart` (because it needs widget
/// imports). This class only exposes small, testable helpers so screens don't
/// hand-write paths.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

class AppNavigator {
  AppNavigator._();

  static void go(BuildContext context, String location) => context.go(location);

  static void push(BuildContext context, String location) =>
      context.push(location);

  static void replace(BuildContext context, String location) =>
      context.replace(location);

  static void pop(BuildContext context, [Object? result]) =>
      context.pop(result);

  /// Returns to the previous screen when possible, otherwise goes [to].
  ///
  /// Useful after an action that may be the first thing a deep-linked user
  /// sees (e.g. after checkout there may be nothing beneath us).
  static void popOrGo(BuildContext context, String to) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(to);
    }
  }

  static void toBookDetails(BuildContext context, String bookId) =>
      context.push(AppRoutes.bookDetails(bookId));

  static void toOrderDetails(BuildContext context, String orderId) =>
      context.push(AppRoutes.orderDetails(orderId));

  static void toTrackOrder(BuildContext context, String orderId) =>
      context.push(AppRoutes.trackOrder(orderId));
}

/// Convenience extensions used by auth screens to route by role.
extension AppAuthNavigation on BuildContext {
  /// Sends the signed-in user to the correct home for their role.
  ///
  /// Admins land on the admin dashboard; everyone else on the customer home.
  /// Pass [isAdmin] (e.g. `auth.isAdmin`) to avoid importing the provider here.
  void goAfterAuth({required bool isAdmin}) {
    if (isAdmin) {
      go(AppRoutes.adminDashboardPath);
    } else {
      go(AppRoutes.homePath);
    }
  }
}
