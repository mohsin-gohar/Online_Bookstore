import 'model_helpers.dart';

/// A frequently-asked question shown on the Help screen.
///
/// Mirrors the `GET /faqs` payload:
/// `id, question, answer, category, is_published, sort_order`.
class FaqModel {
  const FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    this.category = 'General',
    this.sortOrder = 0,
  });

  final String id;
  final String question;
  final String answer;
  final String category;
  final int sortOrder;

  factory FaqModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return FaqModel(
      id: parseString(m['id'] ?? id),
      question: parseString(m['question']),
      answer: parseString(m['answer']),
      category: parseString(m['category']).isEmpty
          ? 'General'
          : parseString(m['category']),
      sortOrder: parseInt(m['sortOrder']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'question': question,
    'answer': answer,
    'category': category,
    'sort_order': sortOrder,
  };

  @override
  bool operator ==(Object other) => other is FaqModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
