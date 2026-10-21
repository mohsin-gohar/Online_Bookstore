import 'package:bookstore_app/data/models/order_model.dart';
import 'package:bookstore_app/data/models/order_status.dart';
import 'package:bookstore_app/data/models/user_model.dart';
import 'factories/fakes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeDataFactory.book', () {
    test('produces a book with all required fields populated', () {
      final book = FakeDataFactory.book();
      expect(book.id, isNotEmpty);
      expect(book.title, isNotEmpty);
      expect(book.author, isNotEmpty);
      expect(book.price, greaterThan(0));
      expect(book.stock, greaterThanOrEqualTo(0));
      expect(book.categoryId, isNotEmpty);
      expect(book.categoryName, isNotEmpty);
      expect(book.isInStock, isTrue);
    });

    test('honors explicit overrides', () {
      final book = FakeDataFactory.book(
        title: 'My Test Book',
        price: 9.99,
        stock: 0,
        isBestseller: true,
      );
      expect(book.title, 'My Test Book');
      expect(book.price, 9.99);
      expect(book.stock, 0);
      expect(book.isOutOfStock, isTrue);
      expect(book.isBestseller, isTrue);
    });

    test('generates unique ids across calls', () {
      final a = FakeDataFactory.book();
      final b = FakeDataFactory.book();
      expect(a.id, isNot(equals(b.id)));
    });

    test('books() returns the requested count', () {
      final list = FakeDataFactory.books(count: 5);
      expect(list, hasLength(5));
    });
  });

  group('FakeDataFactory.user', () {
    test('produces a customer by default', () {
      final user = FakeDataFactory.user();
      expect(user.role, UserRole.customer);
      expect(user.email, contains('@'));
      expect(user.addresses, isNotEmpty);
      expect(user.paymentMethods, isNotEmpty);
    });

    test('admin() produces an admin user', () {
      final admin = FakeDataFactory.admin();
      expect(admin.isAdmin, isTrue);
      expect(admin.role, UserRole.admin);
    });

    test('admin() overrides pass through', () {
      final admin = FakeDataFactory.admin(
        uid: 'custom_admin',
        name: 'Super Admin',
        email: 'super@admin.com',
      );
      expect(admin.uid, 'custom_admin');
      expect(admin.name, 'Super Admin');
      expect(admin.email, 'super@admin.com');
    });
  });

  group('FakeDataFactory.order', () {
    test('computes shipping and total from items', () {
      final order = FakeDataFactory.order();
      expect(order.subtotal, greaterThan(0));
      expect(
        order.shipping,
        equals(OrderModel.computeShipping(order.subtotal)),
      );
      expect(order.total, equals(order.subtotal + order.shipping));
      expect(order.timeline, isNotEmpty);
    });

    test('honors explicit status', () {
      final delivered = FakeDataFactory.order(status: OrderStatus.delivered);
      expect(delivered.status, OrderStatus.delivered);
      expect(delivered.deliveryDate, isNotNull);
      expect(delivered.isDelivered, isTrue);
    });

    test('free shipping at or above threshold', () {
      final order = FakeDataFactory.order(
        subtotal: OrderModel.freeShippingThreshold,
      );
      expect(order.shipping, 0);
      expect(order.total, equals(order.subtotal));
    });
  });

  group('FakeDataFactory.dataset', () {
    test('returns cross-referencing data', () {
      final data = FakeDataFactory.dataset();
      expect(data.categories, isNotEmpty);
      expect(data.books, isNotEmpty);
      expect(data.users, isNotEmpty);
      expect(data.admin.isAdmin, isTrue);
      expect(data.customers, isNotEmpty);

      // every book references a real category
      final catIds = data.categories.map((c) => c.id).toSet();
      for (final book in data.books) {
        expect(catIds, contains(book.categoryId));
      }

      // every order references a real user
      final userIds = data.users.map((u) => u.uid).toSet();
      for (final order in data.orders) {
        expect(userIds, contains(order.userId));
      }
    });
  });

  group('FakeDataHelpers', () {
    test('bookMap returns a map with id', () {
      final map = FakeDataHelpers.bookMap(id: 'b99', title: 'Mapped Book');
      expect(map['id'], 'b99');
      expect(map['title'], 'Mapped Book');
      expect(map.containsKey('price'), isTrue);
    });

    test('bookMaps returns a list of maps', () {
      final maps = FakeDataHelpers.bookMaps(count: 3);
      expect(maps, hasLength(3));
      expect(maps.first.containsKey('id'), isTrue);
    });
  });
}
