import 'package:dio/dio.dart';

import '../mock/mock_transport.dart';
import '../models/api_response.dart';
import 'api_client.dart';
import 'app_exceptions.dart';

/// The transport the repositories talk to.
///
/// The app supports two backends behind this one interface:
///
///  * [HttpApiTransport] — a real Laravel server (Dio over HTTP).
///  * `MockApiTransport` (`lib/data/mock/mock_transport.dart`) — an in-memory
///    server that answers the *same* paths with the *same* envelope, so the
///    app runs without a backend.
///
/// Because both backends implement the same contract, a repository behaves
/// identically in mock mode and live mode — the mock is effectively an
/// executable specification of the API.
abstract class ApiTransport {
  /// `GET {path}`.
  Future<ApiResponse> get(String path, {Map<String, dynamic>? query});

  /// `POST {path}`.
  Future<ApiResponse> post(String path, {Object? body});

  /// `PUT {path}`.
  Future<ApiResponse> put(String path, {Object? body});

  /// `PATCH {path}`.
  Future<ApiResponse> patch(String path, {Object? body});

  /// `DELETE {path}`.
  Future<ApiResponse> delete(String path, {Object? body});

  /// `POST {path}` as `multipart/form-data`.
  Future<ApiResponse> upload(String path, FormData formData);
}

/// The live transport: a thin adapter over [ApiClient] with automatic
/// fallback to [MockApiTransport] when the local Laravel server is offline.
class HttpApiTransport implements ApiTransport {
  HttpApiTransport(this._client)
    : _fallback = MockApiTransport(tokenStorage: _client.tokenStorage);

  final ApiClient _client;
  final MockApiTransport _fallback;

  @override
  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) async {
    try {
      return await _client.get(path, query: query);
    } on NetworkException {
      return _fallback.get(path, query: query);
    }
  }

  @override
  Future<ApiResponse> post(String path, {Object? body}) async {
    try {
      return await _client.post(path, body: body);
    } on NetworkException {
      return _fallback.post(path, body: body);
    }
  }

  @override
  Future<ApiResponse> put(String path, {Object? body}) async {
    try {
      return await _client.put(path, body: body);
    } on NetworkException {
      return _fallback.put(path, body: body);
    }
  }

  @override
  Future<ApiResponse> patch(String path, {Object? body}) async {
    try {
      return await _client.patch(path, body: body);
    } on NetworkException {
      return _fallback.patch(path, body: body);
    }
  }

  @override
  Future<ApiResponse> delete(String path, {Object? body}) async {
    try {
      return await _client.delete(path, body: body);
    } on NetworkException {
      return _fallback.delete(path, body: body);
    }
  }

  @override
  Future<ApiResponse> upload(String path, FormData formData) async {
    try {
      return await _client.upload(path, formData);
    } on NetworkException {
      return _fallback.upload(path, formData);
    }
  }
}
