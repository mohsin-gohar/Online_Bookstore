// Integration-style tests for the mock backend.
//
// The mock transport implements the same Laravel contract as the live API, so
// these tests double as a description of what the server must do.

import 'package:bookstore_app/data/models/book_model.dart';
import 'package:bookstore_app/data/models/cart_model.dart';
import 'package:bookstore_app/data/models/order_item_model.dart';
import 'package:bookstore_app/data/models/order_model.dart';
import 'package:bookstore_app/data/models/order_status.dart';
import 'package:bookstore_app/data/models/page_result.dart';
import 'package:bookstore_app/data/models/review_model.dart';
import 'package:bookstore_app/data/models/user_model.dart';
import 'package:bookstore_app/data/mock/demo_catalog.dart';
import 'package:bookstore_app/data/repositories/auth_repository.dart';
import 'package:bookstore_app/data/repositories/author_repository.dart';
import 'package:bookstore_app/data/repositories/book_repository.dart';
import 'package:bookstore_app/data/repositories/cart_repository.dart';
import 'package:bookstore_app/data/repositories/category_repository.dart';
import 'package:bookstore_app/data/repositories/order_repository.dart';
import 'package:bookstore_app/data/repositories/review_repository.dart';
import 'package:bookstore_app/data/repositories/support_repository.dart';
import 'package:bookstore_app/data/services/api_factory.dart';
import 'package:bookstore_app/data/services/app_exceptions.dart';
import 'package:bookstore_app/data/services/token_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TokenStorageService tokens;
  late MockTransportFixture fixture;

  setUp(() {
    tokens = TokenStorageService();
    fixture = MockTransportFixture(tokens);
  });

  group('Mock backend — catalogue', () {
    test('lists the demo catalogue', () async {
      final PageResult<BookModel> page = await fixture.books.queryBooks(
        const BookQuery(pageSize: 50),
      );

      expect(page.items, isNotEmpty);
      expect(page.items.length, greaterThanOrEqualTo(18));
      expect(page.total, greaterThanOrEqualTo(18));
    });

    test('filters by category', () async {
      final PageResult<BookModel> page = await fixture.books.queryBooks(
        const BookQuery(categoryId: catFiction, pageSize: 50),
      );

      expect(page.items, isNotEmpty);
      expect(
        page.items.every((BookModel b) => b.categoryId == catFiction),
        isTrue,
      );
    });

    test('sorts by price ascending', () async {
      final PageResult<BookModel> page = await fixture.books.queryBooks(
        const BookQuery(sort: BookSort.priceLowHigh, pageSize: 50),
      );

      final List<double> prices = page.items
          .map((BookModel b) => b.price)
          .toList();
      final List<double> sorted = List<double>.of(prices)..sort();
      expect(prices, sorted);
    });

    test('sorts by price descending', () async {
      final PageResult<BookModel> page = await fixture.books.queryBooks(
        const BookQuery(sort: BookSort.priceHighLow, pageSize: 50),
      );

      final List<double> prices = page.items
          .map((BookModel b) => b.price)
          .toList();
      final List<double> sorted = List<double>.of(prices)
        ..sort((double a, double b) => b.compareTo(a));
      expect(prices, sorted);
    });

    test('searches by title, author and genre', () async {
      final PageResult<BookModel> byTitle = await fixture.books.queryBooks(
        const BookQuery(searchTerm: 'Hobbit', pageSize: 50),
      );
      expect(
        byTitle.items.any((BookModel b) => b.title.contains('Hobbit')),
        isTrue,
      );

      final PageResult<BookModel> byAuthor = await fixture.books.queryBooks(
        const BookQuery(searchTerm: 'Tolkien', pageSize: 50),
      );
      expect(byAuthor.items, isNotEmpty);

      final PageResult<BookModel> byGenre = await fixture.books.queryBooks(
        const BookQuery(searchTerm: 'Comics', pageSize: 50),
      );
      expect(byGenre.items, isNotEmpty);
    });

    test('filters by price range, rating and availability', () async {
      final PageResult<BookModel> page = await fixture.books.queryBooks(
        const BookQuery(minPrice: 15, maxPrice: 30, pageSize: 50),
      );
      for (final BookModel book in page.items) {
        expect(book.price, greaterThanOrEqualTo(15));
        expect(book.price, lessThanOrEqualTo(30));
      }

      final PageResult<BookModel> inStock = await fixture.books.queryBooks(
        const BookQuery(inStockOnly: true, pageSize: 50),
      );
      expect(inStock.items.every((BookModel b) => b.stock > 0), isTrue);
    });

    test('filters by author id', () async {
      final PageResult<BookModel> page = await fixture.books.queryBooks(
        const BookQuery(authorId: 'author_moore', pageSize: 50),
      );
      expect(page.items, isNotEmpty);
      expect(
        page.items.every((BookModel b) => b.authorId == 'author_moore'),
        isTrue,
      );
    });

    test('exposes categories', () async {
      final categories = await fixture.categories.getCategories();
      expect(categories.length, greaterThanOrEqualTo(4));
      expect(categories.first.name, isNotEmpty);
    });
  });

  group('Mock backend — authentication', () {
    test('registers, signs in and signs out', () async {
      final UserModel created = await fixture.auth.signUp(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        password: 'secret123',
        phone: '+92 300 1234567',
      );

      expect(created.name, 'Ada Lovelace');
      expect(created.email, 'ada@example.com');
      expect(created.role, UserRole.customer);
      expect(await tokens.readToken(), isNotNull);

      final UserModel? current = await fixture.auth.getCurrentUser();
      expect(current, isNotNull);
      expect(current!.uid, created.uid);

      await fixture.auth.signOut();
      expect(await tokens.readToken(), isNull);
      expect(await fixture.auth.getCurrentUser(), isNull);
    });

    test('rejects a duplicate e-mail with a field error', () async {
      await fixture.auth.signUp(
        name: 'Ada',
        email: 'dup@example.com',
        password: 'secret123',
      );

      expect(
        () => fixture.auth.signUp(
          name: 'Ada Again',
          email: 'dup@example.com',
          password: 'secret123',
        ),
        throwsA(
          isA<ValidationException>().having(
            (ValidationException e) => e.fieldErrors['email'],
            'email field error',
            isNotNull,
          ),
        ),
      );
    });

    test('rejects a wrong password', () async {
      await fixture.auth.signUp(
        name: 'Ada',
        email: 'pw@example.com',
        password: 'secret123',
      );

      expect(
        () => fixture.auth.signIn(
          email: 'pw@example.com',
          password: 'wrong-password',
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test('protected endpoints need a session', () async {
      expect(
        () => fixture.cart.getCart('someone'),
        throwsA(isA<UnauthenticatedException>()),
      );
    });
  });

  group('Mock backend — shopping', () {
    test('adds, updates and clears cart lines', () async {
      await fixture.auth.signUp(
        name: 'Grace',
        email: 'grace@example.com',
        password: 'secret123',
      );

      final BookModel book = (await fixture.books.queryBooks(
        const BookQuery(pageSize: 1),
      )).items.first;

      CartModel cart = await fixture.cart.addItem('u', book, qty: 2);
      expect(cart.items.length, 1);
      expect(cart.items.first.qty, 2);

      cart = await fixture.cart.updateQty('u', book.id, 3);
      expect(cart.items.first.qty, 3);

      cart = await fixture.cart.removeItem('u', book.id);
      expect(cart.items, isEmpty);
    });

    test('places an order and reduces the stock', () async {
      await fixture.auth.signUp(
        name: 'Linus',
        email: 'linus@example.com',
        password: 'secret123',
      );

      final BookModel book = (await fixture.books.queryBooks(
        const BookQuery(pageSize: 1),
      )).items.first;
      final int stockBefore = book.stock;

      await fixture.cart.addItem('u', book, qty: 1);

      final OrderModel order = await fixture.orders.placeOrder(
        OrderModel(
          id: '',
          userId: 'u',
          userName: 'Linus',
          items: <OrderItemModel>[
            OrderItemModel(
              bookId: book.id,
              title: book.title,
              price: book.price,
              qty: 1,
              coverImage: book.coverImage,
            ),
          ],
          subtotal: book.price,
          shipping: 5.99,
          total: book.price + 5.99,
          status: OrderStatus.pending,
          address: '1 Analytical Engine Way',
          paymentMethod: 'Cash on Delivery',
        ),
      );

      expect(order.id, isNotEmpty);
      expect(order.status, OrderStatus.pending);
      expect(order.timeline, isNotEmpty);

      final BookModel? after = await fixture.books.getBook(book.id);
      expect(after!.stock, stockBefore - 1);
    });
  });

  group('Mock backend — help', () {
    test('serves the bundled FAQs', () async {
      final faqs = await fixture.support.getFaqs();
      expect(faqs, isNotEmpty);
      expect(faqs.first.question, isNotEmpty);
      expect(faqs.first.answer, isNotEmpty);
    });
  });

  group('Mock backend — reviews', () {
    test('lists the reviews of a book', () async {
      final List<ReviewModel> reviews = await fixture.reviews.getBookReviews(
        'book_1',
      );

      expect(reviews, isNotEmpty);
      expect(reviews.first.bookId, 'book_1');
    });

    test('writes, edits and deletes a review', () async {
      await fixture.auth.signUp(
        name: 'Maya',
        email: 'maya@example.com',
        password: 'secret123',
      );

      final ReviewModel created = await fixture.reviews.addReview(
        ReviewModel(
          id: '',
          bookId: 'book_2',
          userId: 'u',
          userName: 'Maya',
          rating: 4,
          comment: 'Slow to start, worth it.',
        ),
      );

      expect(created.id, isNotEmpty);
      expect(created.rating, 4);

      await fixture.reviews.updateReview(
        created.copyWith(rating: 5, comment: 'Even better on the second read.'),
      );

      final List<ReviewModel> after = await fixture.reviews.getBookReviews(
        'book_2',
      );
      final ReviewModel mine = after.firstWhere(
        (ReviewModel r) => r.id == created.id,
      );
      expect(mine.rating, 5);

      await fixture.reviews.deleteReview(created.id, 'book_2');
      final List<ReviewModel> final_ = await fixture.reviews.getBookReviews(
        'book_2',
      );
      expect(final_.any((ReviewModel r) => r.id == created.id), isFalse);
    });

    test(
      'refreshes the book rating aggregate after a review is written',
      () async {
        await fixture.auth.signUp(
          name: 'Maya',
          email: 'maya@example.com',
          password: 'secret123',
        );

        final BookModel before = (await fixture.books.getBook('book_3'))!;
        expect(before.reviewCount, greaterThan(0));

        // Writing a review PATCHes the recomputed aggregate back to
        // `/admin/books/{id}`.
        await fixture.reviews.addReview(
          ReviewModel(
            id: '',
            bookId: 'book_3',
            userId: 'u',
            userName: 'Maya',
            rating: 4,
            comment: 'Slow to start, worth it.',
          ),
        );

        final BookModel after = (await fixture.books.getBook('book_3'))!;
        expect(after.rating, 4.0);
        expect(after.reviewCount, 1);

        // The PATCH route updates the aggregate pair - and nothing else.
        final BookModel other = (await fixture.books.getBook('book_4'))!;
        await fixture.books.updateRatingAggregate(
          'book_4',
          rating: 3.5,
          reviewCount: 42,
        );

        final BookModel patched = (await fixture.books.getBook('book_4'))!;
        expect(patched.rating, 3.5);
        expect(patched.reviewCount, 42);
        expect(patched.title, other.title);
        expect(patched.price, other.price);
        expect(patched.stock, other.stock);
      },
    );

    test('rejects a review with an out-of-range rating', () async {
      expect(
        () => fixture.reviews.addReview(
          ReviewModel(
            id: '',
            bookId: 'book_2',
            userId: 'u',
            userName: 'Maya',
            rating: 9,
            comment: 'Nope.',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Mock backend — reference data', () {
    test('returns a single category and a single author', () async {
      final category = await fixture.categories.getCategory(catFiction);
      expect(category, isNotNull);
      expect(category!.name, isNotEmpty);

      final author = await fixture.authors.getAuthor('author_tolkien');
      expect(author, isNotNull);
      expect(author!.name, 'J. R. R. Tolkien');
    });

    test('searches authors by name', () async {
      final authors = await fixture.authors.searchAuthors('tolkien');
      expect(authors, isNotEmpty);
      expect(authors.first.name, contains('Tolkien'));
    });

    test('returns the books of an author', () async {
      final books = await fixture.authors.getBooksByAuthor('author_tolkien');
      expect(books, isNotEmpty);
      expect(
        books.every((BookModel b) => b.authorId == 'author_tolkien'),
        isTrue,
      );
    });
  });
}

/// Bundles the repositories over a single mock transport.
class MockTransportFixture {
  MockTransportFixture(this.tokens) {
    final transport = createMockTransport(tokens);
    ApiFactory.overrideTransport(transport);
    auth = AuthRepository(transport: transport, tokenStorage: tokens);
    books = BookRepository(transport: transport);
    categories = CategoryRepository(transport: transport);
    cart = CartRepository(transport: transport);
    orders = OrderRepository(transport: transport);
    reviews = ReviewRepository(
      transport: transport,
      bookRepository: BookRepository(transport: transport),
    );
    authors = AuthorRepository(transport: transport);
    support = SupportRepository(transport: transport);
  }

  final TokenStorageService tokens;

  late final AuthRepository auth;
  late final BookRepository books;
  late final CategoryRepository categories;
  late final CartRepository cart;
  late final OrderRepository orders;
  late final ReviewRepository reviews;
  late final AuthorRepository authors;
  late final SupportRepository support;
}
