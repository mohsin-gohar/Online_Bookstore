import 'dart:async';
import 'dart:developer' as developer;

import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import '../services/api_factory.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';

/// Reads and writes the signed-in user's profile.
///
/// Backed by `GET /me`, `PUT /me` and (for admins) `GET /admin/users`.
class UserRepository {
  UserRepository({ApiTransport? transport})
    : _api = transport ?? ApiFactory.transport;

  final ApiTransport _api;

  /// Fetches the profile of the signed-in user, or null when there is no
  /// session.
  Future<UserModel?> getUser(String uid) async {
    if (uid.isEmpty) throw const ValidationException('Missing user id.');
    try {
      final ApiResponse response = await _api.get(ApiConstants.me);
      if (response.data == null) return null;
      return UserModel.fromMap(response.map);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log('UserRepository.getUser failed', error: e, stackTrace: s);
      throw const ServerException('Could not load your profile.');
    }
  }

  /// Creates the profile if the server does not have one yet (idempotent).
  ///
  /// With a Laravel backend the profile is created by `/auth/register` and
  /// `/auth/google`, so this is a no-op that simply reads the current user.
  Future<UserModel> createUserIfMissing(UserModel user) async {
    final UserModel? existing = await getUser(user.uid);
    if (existing != null) return existing;

    await upsertUser(user);
    return user;
  }

  /// Creates or updates the full profile.
  Future<void> upsertUser(UserModel user) async {
    try {
      await _api.put(
        ApiConstants.me,
        body: <String, dynamic>{
          'name': user.name,
          'phone': user.phone,
          'photo_url': user.photoUrl,
        },
      );
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'UserRepository.upsertUser failed',
        error: e,
        stackTrace: s,
      );
      throw const ServerException('Could not save your profile.');
    }
  }

  /// Partially updates profile fields (name, phone, photoUrl…).
  Future<void> updateProfile(
    String uid, {
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (photoUrl != null) data['photo_url'] = photoUrl;
    if (data.isEmpty) return;

    try {
      await _api.put(ApiConstants.me, body: data);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'UserRepository.updateProfile failed',
        error: e,
        stackTrace: s,
      );
      throw const ServerException('Could not update your profile.');
    }
  }

  /// Changes the password of the signed-in user.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.put(
      ApiConstants.mePassword,
      body: <String, dynamic>{
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  /// Live view of the signed-in user's profile.
  ///
  /// The REST API has no push channel, so this polls while it is listened to.
  /// Only the admin dashboard and the profile screen subscribe to it.
  Stream<UserModel?> watchUser(String uid) {
    return pollStream<UserModel?>(
      fetch: () async {
        try {
          final ApiResponse response = await _api.get(ApiConstants.me);
          if (response.data == null) return null;
          return UserModel.fromMap(response.map);
        } on AppException {
          rethrow;
        }
      },
      interval: const Duration(seconds: 20),
    );
  }

  /// Admin: lists all users, newest first.
  Future<List<UserModel>> getAllUsers({int limit = 100}) async {
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.adminUsers,
        query: <String, dynamic>{'per_page': limit},
      );
      return response.list
          .map((Map<String, dynamic> m) => UserModel.fromMap(m))
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'UserRepository.getAllUsers failed',
        error: e,
        stackTrace: s,
      );
      throw const ServerException('Could not load the users.');
    }
  }

  /// Admin: blocks or unblocks an account.
  Future<void> setBlocked(String uid, bool blocked) async {
    await _api.patch(
      ApiConstants.adminUserBlock(uid),
      body: <String, dynamic>{'is_blocked': blocked},
    );
  }
}

/// Emits the result of [fetch] immediately and then again every [interval]
/// until the listener cancels.
///
/// Used to give the REST-backed repositories the "live" feel that the demo
/// streams provided, without hammering the server.
Stream<T> pollStream<T>({
  required Future<T> Function() fetch,
  required Duration interval,
}) {
  late StreamController<T> controller;
  Timer? timer;

  Future<void> emit() async {
    try {
      final T value = await fetch();
      if (!controller.isClosed) controller.add(value);
    } catch (e, s) {
      developer.log('pollStream failed', error: e, stackTrace: s);
    }
  }

  controller = StreamController<T>(
    onListen: () {
      emit();
      timer = Timer.periodic(interval, (_) => emit());
    },
    onCancel: () {
      timer?.cancel();
      timer = null;
    },
  );

  return controller.stream;
}
