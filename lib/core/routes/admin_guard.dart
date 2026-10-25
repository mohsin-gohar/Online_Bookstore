import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/auth_provider.dart';
import 'app_routes.dart';

/// Route guard for the admin area.
///
/// Returns a redirect location when the current user is not an admin, or null
/// to allow navigation. Used as the `redirect` of every `/admin/*` route.
///
/// A GoRouter-level guard can't await, so it reads the already-loaded
/// [AuthProvider] synchronously:
///  • not signed in  → send to login
///  • signed in, not admin → send back to the customer home
class AdminGuard {
  AdminGuard._();

  static String? redirect(BuildContext context, dynamic state) {
    final auth = context.read<AuthProvider>();
    // During session restore we don't know yet whether this is an admin. Send
    // the user nowhere until /me answers, otherwise a page reload on an admin
    // URL flashes the login screen and then bounces back.
    if (auth.status == AuthStatus.unknown) return null;
    if (!auth.isAuthenticated) return AppRoutes.loginPath;
    if (!auth.isAdmin) return AppRoutes.homePath;
    return null; // allowed
  }
}
