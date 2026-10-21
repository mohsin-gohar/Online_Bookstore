import 'model_helpers.dart';
import 'page_result.dart';

/// The Laravel response envelope the whole API speaks.
///
/// ```json
/// { "success": true, "message": "Success", "data": {}, "meta": {} }
/// ```
///
/// Every endpoint returns this shape, so the client can unwrap it in one
/// place and never has to guess whether the payload is nested under `data`.
class ApiResponse {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
  });

  final bool success;
  final String message;

  /// The raw `data` payload — a map, a list, or null.
  final dynamic data;

  /// Pagination metadata, when the endpoint paginates.
  final ApiMeta? meta;

  /// Parses an envelope from a decoded JSON body.
  ///
  /// A payload that does not match the envelope is treated as a bare body, so
  /// the client also works against a plain (non-enveloped) endpoint.
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    final bool hasEnvelope =
        json.containsKey('success') ||
        json.containsKey('data') ||
        json.containsKey('message');

    if (!hasEnvelope) {
      return ApiResponse(success: true, message: 'Success', data: json);
    }

    return ApiResponse(
      success: parseBool(json['success'], fallback: true),
      message: parseString(json['message']).isEmpty
          ? 'Success'
          : parseString(json['message']),
      data: json['data'],
      meta: json['meta'] is Map
          ? ApiMeta.fromJson((json['meta'] as Map).cast<String, dynamic>())
          : null,
    );
  }

  /// The payload as a single, key-normalised map (empty when it is a list).
  Map<String, dynamic> get map => normalizeMap(data);

  /// The payload as a list of key-normalised maps (empty when it is a map).
  List<Map<String, dynamic>> get list => normalizeMapList(data);

  /// True when the payload is a list.
  bool get isList => data is List;

  /// True when the payload is a map.
  bool get isMap => data is Map;

  /// The pagination metadata, or an empty one when the endpoint did not
  /// paginate.
  ApiMeta get pagination => meta ?? const ApiMeta();

  /// Builds a [PageResult] from this response's payload and metadata.
  PageResult<T> toPageResult<T>(T Function(Map<String, dynamic> map) fromMap) {
    final List<Map<String, dynamic>> raw = list;
    final List<T> items = raw.map(fromMap).toList(growable: false);
    return pagination.toPageResult(items);
  }
}

/// Pagination metadata mirrored from Laravel's `meta` block.
///
/// ```json
/// { "current_page": 1, "last_page": 4, "per_page": 20, "total": 78 }
/// ```
class ApiMeta {
  const ApiMeta({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 20,
    this.total = 0,
    this.from,
    this.to,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  static ApiMeta fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      currentPage: parseInt(json['current_page'], fallback: 1),
      lastPage: parseInt(json['last_page'], fallback: 1),
      perPage: parseInt(json['per_page'], fallback: 20),
      total: parseInt(json['total']),
      from: json['from'] == null ? null : parseInt(json['from']),
      to: json['to'] == null ? null : parseInt(json['to']),
    );
  }

  /// True when the server has another page after this one.
  bool get hasMore => currentPage < lastPage;

  /// Converts this metadata into the app's [PageResult] shape.
  ///
  /// The cursor is the page number, so a cursor-based repository can keep
  /// calling `queryBooks` unchanged while the API is page-based.
  PageResult<T> toPageResult<T>(List<T> items) {
    return PageResult<T>(
      items: items,
      hasMore: hasMore,
      cursor: currentPage,
      total: total,
      currentPage: currentPage,
      lastPage: lastPage,
    );
  }
}
