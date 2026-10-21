import 'model_helpers.dart';

/// A book review with rating, comment and a "like" system.
///
/// Mirrors `reviews/{reviewId}`:
/// `bookId, userId, userName, userPhoto, rating, comment, likes, likedBy[],
/// createdAt`.
class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.userName,
    this.userPhoto = '',
    this.rating = 0,
    this.comment = '',
    this.likes = 0,
    this.likedBy = const [],
    this.createdAt,
  });

  final String id;
  final String bookId;
  final String userId;
  final String userName;
  final String userPhoto;

  /// Star rating, 1–5.
  final double rating;

  final String comment;

  /// Denormalised like count (kept in sync with [likedBy].length).
  final int likes;

  /// Uids who have liked this review (prevents double-liking).
  final List<String> likedBy;

  final DateTime? createdAt;

  // ── Convenience ───────────────────────────

  /// First letter of the reviewer's name, for the avatar fallback.
  String get initial =>
      userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : '?';

  /// Whether [uid] has already liked this review.
  bool isLikedBy(String uid) => likedBy.contains(uid);

  // ── Serialization ─────────────────────────

  factory ReviewModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return ReviewModel(
      id: parseString(m['id'] ?? id),
      bookId: parseString(m['bookId']),
      userId: parseString(m['userId']),
      userName: parseString(m['userName']),
      userPhoto: parseString(m['userPhoto']),
      rating: parseDouble(m['rating']),
      comment: parseString(m['comment']),
      likes: parseInt(m['likes']),
      likedBy: parseStringList(m['likedBy']),
      createdAt: parseDate(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'book_id': bookId,
    'user_id': userId,
    'user_name': userName,
    'user_photo': userPhoto,
    'rating': rating,
    'comment': comment,
    'likes': likes,
    'liked_by': likedBy,
    'created_at': createdAt?.toIso8601String(),
  };

  /// API write payload (id is the path segment, not a field).
  Map<String, dynamic> toApi() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  ReviewModel copyWith({
    String? id,
    String? bookId,
    String? userId,
    String? userName,
    String? userPhoto,
    double? rating,
    String? comment,
    int? likes,
    List<String>? likedBy,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is ReviewModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
