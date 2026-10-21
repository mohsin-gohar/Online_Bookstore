import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';
import '../data/services/app_exceptions.dart';

/// Owns the signed-in user's in-app notifications.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required NotificationRepository repository})
    : _repo = repository;

  final NotificationRepository _repo;

  List<NotificationModel> _items = const [];
  String? _userId;
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get items => _items;
  int get unreadCount => _items.where((n) => !n.read).length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnread => unreadCount > 0;

  // ── Session ───────────────

  Future<void> onUserChanged(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    if (userId == null) {
      _items = const [];
      notifyListeners();
      return;
    }
    await load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repo.getNotifications(_userId!);
    } on AppException catch (e) {
      _error = e.message;
    } catch (e, s) {
      developer.log(
        'NotificationProvider.load failed',
        error: e,
        stackTrace: s,
      );
      _error = const UnknownException().message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mutations ─────────────

  Future<void> markRead(NotificationModel notification) async {
    if (_userId == null || notification.read) return;
    try {
      await _repo.markRead(_userId!, notification.id);
      _items = _items
          .map((n) => n.id == notification.id ? n.copyWith(read: true) : n)
          .toList();
      notifyListeners();
    } catch (e, s) {
      developer.log(
        'NotificationProvider.markRead failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> markAllRead() async {
    if (_userId == null) return;
    try {
      await _repo.markAllRead(_userId!);
      _items = _items.map((n) => n.copyWith(read: true)).toList();
      notifyListeners();
    } catch (e, s) {
      developer.log(
        'NotificationProvider.markAllRead failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> delete(NotificationModel notification) async {
    if (_userId == null) return;
    try {
      await _repo.deleteNotification(_userId!, notification.id);
      _items = _items.where((n) => n.id != notification.id).toList();
      notifyListeners();
    } catch (e, s) {
      developer.log(
        'NotificationProvider.delete failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Pushes a local in-app notification to [userId].
  ///
  /// Called by [OrderProvider] when an order status changes, so the customer
  /// sees an in-app notification without a Cloud Function.
  Future<void> push({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    String orderId = '',
  }) async {
    try {
      final created = await _repo.addNotification(
        userId,
        NotificationModel(
          id: '',
          title: title,
          message: message,
          type: type,
          orderId: orderId,
          createdAt: DateTime.now(),
        ),
      );
      // If this is the current user, prepend to the local list.
      if (userId == _userId) {
        _items = [
          NotificationModel(
            id: created,
            title: title,
            message: message,
            type: type,
            orderId: orderId,
            createdAt: DateTime.now(),
          ),
          ..._items,
        ];
        notifyListeners();
      }
    } catch (e, s) {
      // Notifications are best-effort.
      developer.log(
        'NotificationProvider.push failed',
        error: e,
        stackTrace: s,
      );
    }
  }
}
