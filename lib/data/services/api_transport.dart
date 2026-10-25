import 'package:dio/dio.dart';

import '../models/api_response.dart';
import 'api_client.dart';

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

/// The live transport: a thin adapter over [ApiClient].
///
/// Failures are reported to the caller — live mode never substitutes demo
/// data for a real session. Offline demo use is served by mock mode
/// (`API_MODE=mock`), not by a hidden fallback.
class HttpApiTransport implements ApiTransport {
  HttpApiTransport(this._client);

  final ApiClient _client;

  @override
  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) =>
      _client.get(path, query: query);

  @override
  Future<ApiResponse> post(String path, {Object? body}) =>
      _client.post(path, body: body);

  @override
  Future<ApiResponse> put(String path, {Object? body}) =>
      _client.put(path, body: body);

  @override
  Future<ApiResponse> patch(String path, {Object? body}) =>
      _client.patch(path, body: body);

  @override
  Future<ApiResponse> delete(String path, {Object? body}) =>
      _client.delete(path, body: body);

  @override
  Future<ApiResponse> upload(String path, FormData formData) =>
      _client.upload(path, formData);
}
