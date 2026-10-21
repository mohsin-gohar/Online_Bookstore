import 'model_helpers.dart';

/// A book in the catalog.
///
/// Mirrors the `books/{bookId}` API resource:
/// `title, author, isbn, description, price, stock, coverImage, categoryId,
/// categoryName, rating, reviewCount, isBestseller, isNewArrival, releaseDate,
/// createdAt`.
class BookModel {
  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.isbn = '',
    this.description = '',
    this.price = 0,
    this.stock = 0,
    this.coverImage = '',
    this.categoryId = '',
    this.categoryName = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.isBestseller = false,
    this.isNewArrival = false,
    this.releaseDate,
    this.createdAt,
    this.images = const [],
    this.language = 'English',
    this.pages = 0,
    this.publisher = '',
    this.authorId = '',
  });

  final String id;
  final String title;
  final String author;
  final String isbn;
  final String description;

  /// Selling price in the app currency.
  final double price;

  /// Units in stock; 0 means out of stock.
  final int stock;

  /// Primary cover image URL (served by the API or a CDN).
  final String coverImage;

  final String categoryId;
  final String categoryName;

  /// Average rating (0–5), denormalised for fast list rendering.
  final double rating;

  /// Number of reviews backing [rating].
  final int reviewCount;

  final bool isBestseller;
  final bool isNewArrival;
  final DateTime? releaseDate;
  final DateTime? createdAt;

  /// Optional extra gallery images (cover is always [coverImage]).
  final List<String> images;

  final String language;
  final int pages;
  final String publisher;

  /// Id of the author row this book belongs to (empty when unlinked).
  final String authorId;

  // ── Convenience ───────────────────────────

  bool get isInStock => stock > 0;
  bool get isOutOfStock => stock <= 0;

  /// `$12.50` helper kept dependency-free (UI can also use Formatters.price).
  String get priceLabel => '\$${price.toStringAsFixed(2)}';

  /// Rounded rating label, e.g. `4.5`.
  String get ratingLabel => rating.toStringAsFixed(1);

  /// All gallery images with the cover first (de-duplicated).
  List<String> get allImages {
    final set = <String>{if (coverImage.isNotEmpty) coverImage, ...images};
    return set.toList(growable: false);
  }

  // ── Serialization ─────────────────────────

  /// Creates a [BookModel] from an API payload.
  ///
  /// Handles legacy field names (imageUrl -> coverImage) and ensures no null
  /// values crash the UI by providing sensible fallbacks.
  factory BookModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return BookModel(
      id: parseString(m['id'] ?? id),
      title: parseString(m['title']),
      author: parseString(m['author']),
      isbn: parseString(m['isbn']),
      description: parseString(m['description']),
      price: parseDouble(m['price'], fallback: 0.0),
      stock: parseInt(m['stock'], fallback: 0),
      // Use coverImage as primary, fallback to legacy imageUrl field if needed.
      coverImage: parseString(
        (m['coverImage'] != null && m['coverImage'].toString().isNotEmpty)
            ? m['coverImage']
            : m['imageUrl'],
      ),
      categoryId: parseString(m['categoryId']),
      categoryName: parseString(m['categoryName']),
      rating: parseDouble(m['rating'], fallback: 0.0),
      reviewCount: parseInt(m['reviewCount'], fallback: 0),
      isBestseller: parseBool(m['isBestseller'], fallback: false),
      isNewArrival: parseBool(m['isNewArrival'], fallback: false),
      releaseDate: parseDate(m['releaseDate']),
      createdAt: parseDate(m['createdAt']),
      images: parseStringList(m['images']),
      language: parseString(m['language']).isEmpty
          ? 'English'
          : parseString(m['language']),
      pages: parseInt(m['pages'], fallback: 0),
      publisher: parseString(m['publisher']),
      authorId: parseString(m['authorId']),
    );
  }

  /// Alias for [fromMap] to match common API naming conventions.
  factory BookModel.fromApi(Map<String, dynamic> map, {String? id}) =>
      BookModel.fromMap(map, id: id);

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'author': author,
    'isbn': isbn,
    'description': description,
    'price': price,
    'stock': stock,
    'cover_image': coverImage,
    'category_id': categoryId,
    'category_name': categoryName,
    'rating': rating,
    'review_count': reviewCount,
    'is_bestseller': isBestseller,
    'is_new_arrival': isNewArrival,
    'release_date': releaseDate?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'images': images,
    'language': language,
    'pages': pages,
    'publisher': publisher,
    'author_id': authorId,
  };

  /// Map used for API writes where the id is the path segment (not a
  /// field inside the document).
  Map<String, dynamic> toApi() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? description,
    double? price,
    int? stock,
    String? coverImage,
    String? categoryId,
    String? categoryName,
    double? rating,
    int? reviewCount,
    bool? isBestseller,
    bool? isNewArrival,
    DateTime? releaseDate,
    DateTime? createdAt,
    List<String>? images,
    String? language,
    int? pages,
    String? publisher,
    String? authorId,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      coverImage: coverImage ?? this.coverImage,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isBestseller: isBestseller ?? this.isBestseller,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      releaseDate: releaseDate ?? this.releaseDate,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
      language: language ?? this.language,
      pages: pages ?? this.pages,
      publisher: publisher ?? this.publisher,
      authorId: authorId ?? this.authorId,
    );
  }

  /// Returns a copy with [qty] removed from stock (never below 0).
  BookModel decrementStock(int qty) =>
      copyWith(stock: (stock - qty).clamp(0, 1 << 31));

  @override
  bool operator ==(Object other) => other is BookModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
