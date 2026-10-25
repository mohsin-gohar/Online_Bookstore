import 'package:bookstore_app/data/models/book_model.dart';
import 'package:bookstore_app/data/models/cart_item_model.dart';
import 'package:bookstore_app/data/models/cart_model.dart';
import 'package:bookstore_app/data/models/category_model.dart';
import 'package:bookstore_app/data/models/order_model.dart';
import 'package:bookstore_app/data/models/order_status.dart';
import 'package:bookstore_app/data/models/review_model.dart';
import 'package:bookstore_app/data/models/wishlist_item_model.dart';
import 'package:bookstore_app/data/models/wishlist_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookModel', () {
    test('round-trips through toMap/fromMap', () {
      final book = BookModel(
        id: 'b1',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        price: 42.5,
        stock: 7,
        categoryId: 'c1',
        categoryName: 'Non-Fiction',
        rating: 4.6,
        reviewCount: 128,
        isBestseller: true,
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = BookModel.fromMap(book.toMap(), id: 'b1');
      expect(restored.title, 'Clean Code');
      expect(restored.price, 42.5);
      expect(restored.stock, 7);
      expect(restored.isBestseller, isTrue);
      expect(restored.createdAt, DateTime(2024, 1, 1));
    });

    test('parses numeric strings and missing fields gracefully', () {
      final restored = BookModel.fromMap({
        'title': 'X',
        'author': 'Y',
        'price': '12.99',
        'stock': '3',
      }, id: 'b2');
      expect(restored.price, 12.99);
      expect(restored.stock, 3);
      expect(restored.isBestseller, isFalse);
      expect(restored.language, 'English');
    });

    test('in-stock helpers', () {
      const inStock = BookModel(id: 'a', title: 'A', author: 'Z', stock: 5);
      const outOfStock = BookModel(id: 'b', title: 'B', author: 'Z', stock: 0);
      expect(inStock.isInStock, isTrue);
      expect(outOfStock.isOutOfStock, isTrue);
    });

    test('decrementStock never goes below zero', () {
      const book = BookModel(id: 'a', title: 'A', author: 'Z', stock: 2);
      expect(book.decrementStock(5).stock, 0);
    });

    test('toApi omits the id field', () {
      const book = BookModel(id: 'a', title: 'A', author: 'Z');
      expect(book.toApi().containsKey('id'), isFalse);
    });
  });

  group('CategoryModel', () {
    test('round-trips', () {
      final category = CategoryModel(
        id: 'c1',
        name: 'Fiction',
        description: 'Stories',
        createdAt: DateTime(2023, 5, 5),
      );
      final restored = CategoryModel.fromMap(category.toMap(), id: 'c1');
      expect(restored.name, 'Fiction');
      expect(restored.createdAt, DateTime(2023, 5, 5));
    });
  });

  group('CartModel', () {
    test('computes counts and subtotal', () {
      const cart = CartModel(
        userId: 'u1',
        items: [
          CartItemModel(bookId: 'b1', title: 'A', price: 10, qty: 2),
          CartItemModel(bookId: 'b2', title: 'B', price: 5.5, qty: 3),
        ],
      );
      expect(cart.itemCount, 5);
      expect(cart.lineCount, 2);
      expect(cart.subtotal, 36.5);
      expect(cart.contains('b1'), isTrue);
      expect(cart.quantityOf('b2'), 3);
      expect(cart.quantityOf('nope'), 0);
    });

    test('round-trips through an API map', () {
      const cart = CartModel(
        userId: 'u1',
        items: [CartItemModel(bookId: 'b1', title: 'A', price: 10, qty: 1)],
      );
      final restored = CartModel.fromMap(cart.toMap(), userId: 'u1');
      expect(restored.items.single.bookId, 'b1');
      expect(restored.subtotal, 10);
    });

    test('empty cart factory', () {
      expect(CartModel.empty('u1').isEmpty, isTrue);
    });
  });

  group('WishlistModel', () {
    test('counts and membership', () {
      final wishlist = WishlistModel(
        userId: 'u1',
        items: [
          WishlistItemModel(
            bookId: 'b1',
            title: 'A',
            price: 9.99,
            addedAt: DateTime(2024, 2, 2),
          ),
        ],
      );
      expect(wishlist.count, 1);
      expect(wishlist.contains('b1'), isTrue);
      final restored = WishlistModel.fromMap(wishlist.toMap(), userId: 'u1');
      expect(restored.items.single.addedAt, DateTime(2024, 2, 2));
    });
  });

  group('OrderStatus', () {
    test('parses strings', () {
      expect(OrderStatus.fromString('confirmed'), OrderStatus.confirmed);
      expect(OrderStatus.fromString('CANCELED'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('bogus'), OrderStatus.pending);
    });

    test('enforces forward-only transitions', () {
      expect(
        OrderStatus.pending.canTransitionTo(OrderStatus.confirmed),
        isTrue,
      );
      expect(
        OrderStatus.pending.canTransitionTo(OrderStatus.delivered),
        isFalse,
      );
      expect(
        OrderStatus.delivered.canTransitionTo(OrderStatus.cancelled),
        isFalse,
      );
      expect(
        OrderStatus.shipped.canTransitionTo(OrderStatus.cancelled),
        isTrue,
      );
    });

    test('timeline index and progress', () {
      expect(OrderStatus.pending.timelineIndex, 0);
      expect(OrderStatus.delivered.timelineIndex, 3);
      expect(OrderStatus.cancelled.timelineIndex, -1);
    });
  });

  group('OrderModel', () {
    test('round-trips including timeline', () {
      final order = OrderModel(
        id: 'o1',
        userId: 'u1',
        userName: 'Jane',
        items: const [],
        subtotal: 40,
        shipping: 5,
        discount: 8,
        promoCode: 'APTECH20',
        total: 37,
        status: OrderStatus.confirmed,
        orderDate: DateTime(2024, 3, 3),
      );
      final restored = OrderModel.fromMap(order.toMap(), id: 'o1');
      expect(restored.total, 37);
      expect(restored.discount, 8);
      expect(restored.promoCode, 'APTECH20');
      expect(restored.status, OrderStatus.confirmed);
      expect(restored.orderDate, DateTime(2024, 3, 3));
    });

    test('progress is 0 when cancelled', () {
      final order = OrderModel(
        id: 'o2',
        userId: 'u1',
        userName: 'Jane',
        status: OrderStatus.cancelled,
      );
      expect(order.progress, 0);
    });
  });

  group('OrderModel.computeShipping', () {
    test('empty cart never charges shipping', () {
      expect(OrderModel.computeShipping(0), 0);
    });

    test('flat fee below the threshold', () {
      expect(OrderModel.computeShipping(10), OrderModel.flatShippingFee);
      expect(OrderModel.computeShipping(49.99), OrderModel.flatShippingFee);
    });

    test('free at and above the threshold', () {
      expect(OrderModel.computeShipping(50), 0);
      expect(OrderModel.computeShipping(75.25), 0);
    });

    test('cart subtotal + shipping equals the order total', () {
      const subtotal = 42.50;
      final total = subtotal + OrderModel.computeShipping(subtotal);
      expect(total, closeTo(48.49, 0.001));
    });
  });

  group('ReviewModel', () {
    test('round-trips with likedBy', () {
      final review = ReviewModel(
        id: 'r1',
        bookId: 'b1',
        userId: 'u1',
        userName: 'Jane',
        rating: 5,
        comment: 'Great!',
        likes: 2,
        likedBy: const ['u2', 'u3'],
        createdAt: DateTime(2024, 4, 4),
      );
      final restored = ReviewModel.fromMap(review.toMap(), id: 'r1');
      expect(restored.rating, 5);
      expect(restored.likedBy, ['u2', 'u3']);
      expect(restored.isLikedBy('u2'), isTrue);
      expect(restored.isLikedBy('u9'), isFalse);
      expect(restored.initial, 'J');
    });
  });
}
