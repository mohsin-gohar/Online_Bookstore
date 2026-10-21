import 'package:bookstore_app/data/models/book_model.dart';
import 'package:bookstore_app/data/models/category_model.dart';
import 'package:bookstore_app/presentation/common_widgets/book_card.dart';
import 'package:bookstore_app/presentation/common_widgets/empty_state.dart';
import 'package:bookstore_app/presentation/common_widgets/error_state.dart';
import 'package:bookstore_app/presentation/common_widgets/section_header.dart';
import 'package:bookstore_app/presentation/home/widgets/category_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] inside a minimal MaterialApp so theme + localizations resolve.
Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('BookCard', () {
    final book = BookModel(
      id: 'b1',
      title: 'The Pragmatic Programmer',
      author: 'Andrew Hunt',
      price: 39.99,
      stock: 5,
      rating: 4.8,
      reviewCount: 42,
      isBestseller: true,
    );

    testWidgets('grid layout shows title, author, price and rating', (
      tester,
    ) async {
      var tapped = false;
      await _pump(tester, BookCard(book: book, onTap: () => tapped = true));

      expect(find.text('The Pragmatic Programmer'), findsOneWidget);
      expect(find.text('Andrew Hunt'), findsOneWidget);
      expect(find.text(r'$39.99'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('Bestseller'), findsOneWidget);

      await tester.tap(find.text('The Pragmatic Programmer'));
      expect(tapped, isTrue);
    });

    testWidgets('shows Out of stock badge when stock is zero', (tester) async {
      final outOfStock = book.copyWith(stock: 0, isBestseller: false);
      await _pump(tester, BookCard(book: outOfStock, onTap: () {}));
      expect(find.text('Out of stock'), findsOneWidget);
    });

    testWidgets('tapping wishlist heart fires the callback', (tester) async {
      var toggled = false;
      await _pump(
        tester,
        BookCard(
          book: book,
          onTap: () {},
          onToggleWishlist: () => toggled = true,
        ),
      );
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect(toggled, isTrue);
    });

    testWidgets('list layout renders title and author', (tester) async {
      await _pump(
        tester,
        BookCard(
          book: book,
          layout: BookCardLayout.list,
          onTap: () {},
          onToggleWishlist: () {},
        ),
      );
      expect(find.text('The Pragmatic Programmer'), findsOneWidget);
      expect(find.text('Andrew Hunt'), findsOneWidget);
    });

    test('heroTag is stable and unique per book', () {
      expect(BookCard.heroTag('b1'), BookCard.heroTag('b1'));
      expect(BookCard.heroTag('b1'), isNot(BookCard.heroTag('b2')));
    });
  });

  group('CategoryTile', () {
    testWidgets('shows the category initial when no image', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        CategoryTile(
          category: const CategoryModel(id: 'c1', name: 'Fiction'),
          onTap: () => tapped = true,
        ),
      );
      expect(find.text('F'), findsOneWidget);
      expect(find.text('Fiction'), findsOneWidget);
      await tester.tap(find.text('Fiction'));
      expect(tapped, isTrue);
    });
  });

  group('EmptyState', () {
    testWidgets('renders title, message and action', (tester) async {
      var acted = false;
      await _pump(
        tester,
        EmptyState(
          title: 'Your cart is empty',
          message: 'Add some books to get started.',
          actionLabel: 'Browse',
          onAction: () => acted = true,
        ),
      );
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Add some books to get started.'), findsOneWidget);
      await tester.tap(find.text('Browse'));
      expect(acted, isTrue);
    });
  });

  group('ErrorState', () {
    testWidgets('renders message and retry', (tester) async {
      var retried = false;
      await _pump(
        tester,
        ErrorState(message: 'Network error', onRetry: () => retried = true),
      );
      expect(find.text('Network error'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });
  });

  group('SectionHeader', () {
    testWidgets('shows action and fires callback', (tester) async {
      var acted = false;
      await _pump(
        tester,
        SectionHeader(
          title: 'Bestsellers',
          actionLabel: 'See All',
          onAction: () => acted = true,
        ),
      );
      expect(find.text('Bestsellers'), findsOneWidget);
      await tester.tap(find.text('See All'));
      expect(acted, isTrue);
    });
  });
}
