import 'dart:async';
import 'dart:developer' as developer;

import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/notification_model.dart';
import '../services/api_factory.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';
import 'user_repository.dart' show pollStream;

/// Reads the signed-in user's notifications.
///
/// Backed by `GET /notifications`, `POST /notifications/{id}/read` and
/// `POST /notifications/read-all`.
class NotificationRepository {
  NotificationRepository({ApiTransport? transport})
    : _api = transport ?? ApiFactory.transport;

  final ApiTransport _api;

  /// Loads the user's notifications, newest first.
  Future<List<NotificationModel>> getNotifications(
    String userId, {
    int limit = 50,
  }) async {
    if (userId.isEmpty) throw const UnauthenticatedException();
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.notifications,
        query: <String, dynamic>{'per_page': limit},
      );
      return response.list
          .map((Map<String, dynamic> m) => NotificationModel.fromMap(m))
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'NotificationRepository.getNotifications failed',
        error: e,
        stackTrace: s,
      );
      throw const ServerException('Could not load notifications.');
    }
  }

  /// Live view of the user's notifications.
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return pollStream<List<NotificationModel>>(
      fetch: () => getNotifications(userId),
      interval: const Duration(seconds: 20),
    );
  }

  /// Marks a single notification as read.
  Future<void> markRead(String userId, String notifId) async {
    await _api.post(ApiConstants.notificationRead(notifId));
  }

  /// Marks all of a user's notifications as read.
  Future<void> markAllRead(String userId) async {
    await _api.post(ApiConstants.notificationsReadAll);
  }

  /// Creates a notification for [userId]; returns the new id.
  ///
  /// Used by the admin dashboard when an order changes status.
  Future<String> addNotification(
    String userId,
    NotificationModel notification,
  ) async {
    final ApiResponse response = await _api.post(
      ApiConstants.notifications,
      body: notification.toMap(),
    );
    final String id = response.map['id']?.toString() ?? '';
    return id.isEmpty ? notification.id : id;
  }

  /// Deletes a notification.
  Future<void> deleteNotification(String userId, String notifId) async {
    await _api.delete(ApiConstants.notification(notifId));
  }
}
