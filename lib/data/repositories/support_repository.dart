import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/faq_model.dart';
import '../mock/demo_catalog.dart';
import '../services/api_factory.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';

/// The Help & Support data source.
///
/// Backed by `GET /faqs`, `POST /support/messages` and `POST /uploads`.
///
/// The FAQ list has a **documented local fallback**: when the endpoint is
/// unreachable the bundled demo FAQs are returned so the Help screen always
/// has something useful to show.
class SupportRepository {
  SupportRepository({ApiTransport? transport})
    : _api = transport ?? ApiFactory.transport;

  final ApiTransport _api;

  /// The published FAQs.
  ///
  /// Falls back to the bundled demo list when the server cannot be reached.
  Future<List<FaqModel>> getFaqs({bool useFallback = true}) async {
    try {
      final ApiResponse response = await _api.get(ApiConstants.faqs);
      final List<FaqModel> faqs = response.list
          .map((Map<String, dynamic> m) => FaqModel.fromMap(m))
          .toList(growable: false);
      if (faqs.isNotEmpty) return faqs;
    } on AppException {
      if (!useFallback) rethrow;
    } catch (_) {
      if (!useFallback) rethrow;
    }
    return useFallback ? fallbackFaqs : const [];
  }

  /// Sends a support message. Returns the server's confirmation id.
  Future<String> sendMessage({
    required String subject,
    required String message,
  }) async {
    if (subject.trim().isEmpty) {
      throw const ValidationException('Please add a subject.');
    }
    if (message.trim().length < 10) {
      throw const ValidationException(
        'Please write at least 10 characters so we can help.',
      );
    }

    final ApiResponse response = await _api.post(
      ApiConstants.supportMessages,
      body: <String, dynamic>{
        'subject': subject.trim(),
        'message': message.trim(),
      },
    );
    return response.map['id']?.toString() ?? '';
  }

  /// Uploads an image (e.g. a book cover) and returns its public URL.
  Future<String> uploadImage({
    required String path,
    required String fileName,
    required List<int> bytes,
    String field = 'file',
  }) async {
    final FormData formData = FormData.fromMap(<String, dynamic>{
      field: MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final ApiResponse response = await _api.upload(
      ApiConstants.uploads,
      formData,
    );
    final String url = response.map['url']?.toString() ?? '';
    if (url.isEmpty) {
      throw const ServerException('The upload did not return a URL.');
    }
    return url;
  }

  /// The FAQs bundled with the app — used when the server is unreachable.
  static List<FaqModel> get fallbackFaqs => _fallback;

  static final List<FaqModel> _fallback = demoFaqs
      .map((Map<String, dynamic> m) => FaqModel.fromMap(m))
      .toList(growable: false);
}
