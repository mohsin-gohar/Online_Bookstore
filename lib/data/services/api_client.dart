import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import 'app_exceptions.dart';
import 'token_storage_service.dart';

/// The HTTP transport for the Laravel REST API.
///
/// Responsibilities:
///  * attach the bearer token to every request,
///  * unwrap the `{"success", "message", "data", "meta"}` envelope,
///  * map transport / HTTP failures onto the app's [AppException] hierarchy,
///  * detect an expired session (HTTP 401) and hand control back to the app.
///
/// It knows nothing about models — the repositories above it do the parsing.
class ApiClient {
  ApiClient({Dio? dio, TokenStorageService? tokenStorage, this.onUnauthorized})
    : tokenStorage = tokenStorage ?? TokenStorageService(),
      _dio = dio ?? Dio() {
    _dio.options = _dio.options.copyWith(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      responseType: ResponseType.json,
      headers: <String, dynamic>{
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      // Let the client raise on non-2xx so the error mapper sees them.
      validateStatus: (int? status) =>
          status != null && status >= 200 && status < 300,
    );
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final Dio _dio;

  /// Where the bearer token lives.
  final TokenStorageService tokenStorage;

  /// Invoked when the server rejects the token (HTTP 401) so the app can sign
  /// the user out and clear user-specific cached state.
  final void Function()? onUnauthorized;

  /// The raw client — exposed for the rare caller that needs a bespoke
  /// request (e.g. multipart upload with progress).
  Dio get dio => _dio;

  // ── Verbs ─────────────────────────────────

  /// `GET {path}` with optional [query] parameters.
  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) {
    return _send(
      () => _dio.get<dynamic>(path, queryParameters: _clean(query)),
      canRetry: true,
    );
  }

  /// `POST {path}` with a JSON [body].
  Future<ApiResponse> post(String path, {Object? body}) {
    return _send(() => _dio.post<dynamic>(path, data: body));
  }

  /// `PUT {path}` with a JSON [body].
  Future<ApiResponse> put(String path, {Object? body}) {
    return _send(() => _dio.put<dynamic>(path, data: body));
  }

  /// `PATCH {path}` with a JSON [body].
  Future<ApiResponse> patch(String path, {Object? body}) {
    return _send(() => _dio.patch<dynamic>(path, data: body));
  }

  /// `DELETE {path}`.
  Future<ApiResponse> delete(String path, {Object? body}) {
    return _send(() => _dio.delete<dynamic>(path, data: body));
  }

  /// `POST {path}` as `multipart/form-data` (book-cover uploads).
  Future<ApiResponse> upload(String path, FormData formData) {
    return _send(
      () => _dio.post<dynamic>(
        path,
        data: formData,
        options: Options(sendTimeout: ApiConstants.uploadTimeout),
      ),
    );
  }

  // ── Internals ─────────────────────────────

  Future<ApiResponse> _send(
    Future<Response<dynamic>> Function() request, {
    bool canRetry = false,
  }) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        final Response<dynamic> response = await request();
        final Object? raw = response.data;

        if (raw is! Map) {
          // 204 No Content and friends.
          return const ApiResponse(success: true, message: 'Success');
        }

        final ApiResponse envelope = ApiResponse.fromJson(
          raw.cast<String, dynamic>(),
        );

        if (!envelope.success) {
          throw ServerException(
            envelope.message.isEmpty ? 'Request failed.' : envelope.message,
          );
        }

        return envelope;
      } on DioException catch (e) {
        final mapped = mapError(e);
        if (canRetry && attempts < 3 && mapped is NetworkException) {
          await Future<void>.delayed(Duration(milliseconds: 250 * attempts));
          continue;
        }
        throw mapped;
      } on AppException {
        rethrow;
      } catch (e, s) {
        developer.log('ApiClient request failed', error: e, stackTrace: s);
        throw const UnknownException();
      }
    }
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final String? token = await tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // A missing token simply means an unauthenticated request.
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // An expired session (401) invalidates the stored token and asks the app
    // to sign the user out cleanly.
    if (error.response?.statusCode == 401) {
      await tokenStorage.clear();
      onUnauthorized?.call();
    }
    handler.next(error);
  }

  /// Drops `null`/empty values so the query string stays clean.
  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return null;
    final Map<String, dynamic> out = <String, dynamic>{};
    query.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      out[key] = value;
    });
    return out.isEmpty ? null : out;
  }

  // ── Error mapping ────────────────────────

  /// Translates a [DioException] into the app's [AppException] hierarchy.
  ///
  /// Laravel answers with:
  ///  * `422` → `{"message": "...", "errors": {"field": ["msg"]}}`
  ///  * `401` → unauthenticated / expired session
  ///  * `403` → blocked account or missing permission
  ///  * `404` → not found
  ///  * `409` → conflict (e.g. e-mail already taken)
  ///  * `5xx` → server error
  AppException mapError(DioException error) {
    final int? status = error.response?.statusCode;

    switch (status) {
      case 400:
        return ValidationException(_message(error) ?? 'Invalid request.');
      case 401:
        return const UnauthenticatedException();
      case 403:
        return AccountBlockedException(
          _message(error) ??
              'Your account does not have access to this action.',
        );
      case 404:
        return ServerException(
          _message(error) ?? 'The requested item was not found.',
          'not-found',
        );
      case 409:
        return EmailAlreadyInUseException(
          _message(error) ?? 'This email is already registered.',
        );
      case 422:
        return _validationError(error);
      case 429:
        return const ServerException(
          'Too many attempts. Please wait a moment and try again.',
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          _message(error) ?? 'The server is unavailable. Try again shortly.',
        );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException('The server took too long to respond.');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const NetworkException();
      case DioExceptionType.badCertificate:
        return const NetworkException(
          'The server certificate could not be verified.',
        );
      case DioExceptionType.cancel:
        return const NetworkException('The request was cancelled.');
      case DioExceptionType.badResponse:
        return ServerException(
          _message(error) ?? 'Something went wrong. Please try again.',
        );
    }
  }

  /// Builds a [ValidationException] from Laravel's 422 payload.
  ValidationException _validationError(DioException error) {
    final Object? data = error.response?.data;
    if (data is! Map) {
      return ValidationException(
        _message(error) ?? 'Please check the information you entered.',
      );
    }

    final Map<String, dynamic> json = data.cast<String, dynamic>();
    final Object? rawErrors = json['errors'];

    final Map<String, String> fieldErrors = <String, String>{};
    if (rawErrors is Map) {
      rawErrors.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          fieldErrors[key.toString()] = value.first.toString();
        } else if (value is String) {
          fieldErrors[key.toString()] = value;
        }
      });
    }

    final String message =
        _message(error) ?? 'Please check the information you entered.';

    return ValidationException.withFields(
      fieldErrors.isEmpty ? message : fieldErrors.values.first,
      fieldErrors,
    );
  }

  /// Extracts a human-readable message from an error response body.
  String? _message(DioException error) {
    final Object? data = error.response?.data;
    if (data is Map) {
      final Object? message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    return null;
  }
}
