import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/auth_provider.dart';
import '../../logic/cart_provider.dart';
import '../../logic/notification_provider.dart';
import '../../logic/profile_provider.dart';
import '../../logic/wishlist_provider.dart';

/// Keeps per-user state (cart, wishlist) in sync with the auth session.
///
/// Sits just above `MaterialApp.router` so it reacts to auth changes no matter
/// which screen triggered them (login, logout, blocked-account sign-out). When
/// the signed-in user changes it reloads their cart and wishlist; on sign-out
/// it clears both locally.
class UserSessionSync extends StatefulWidget {
  const UserSessionSync({super.key, required this.child});

  final Widget child;

  @override
  State<UserSessionSync> createState() => _UserSessionSyncState();
}

class _UserSessionSyncState extends State<UserSessionSync> {
  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    // Watch auth so we run the sync whenever the session changes.
    final uid = context.select<AuthProvider, String?>((a) => a.uid);

    if (uid != _lastUid) {
      _lastUid = uid;
      // Defer until after the current frame to avoid setState-during-build in
      // the providers we're about to notify.
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncSession(uid));
    }

    return widget.child;
  }

  Future<void> _syncSession(String? uid) async {
    if (!mounted) return;
    final cart = context.read<CartProvider>();
    final wishlist = context.read<WishlistProvider>();
    final profile = context.read<ProfileProvider>();
    final notifications = context.read<NotificationProvider>();
    final auth = context.read<AuthProvider>();

    // Mirror the freshly-loaded user (addresses/payment methods) and reload the
    // per-user collections. All are cleared when uid is null.
    profile.seed(auth.user);
    await Future.wait([
      cart.onUserChanged(uid),
      wishlist.onUserChanged(uid),
      notifications.onUserChanged(uid),
    ]);
  }
}
