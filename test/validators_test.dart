import 'package:bookstore_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty', () => expect(Validators.email(''), isNotNull));
    test('rejects invalid', () => expect(Validators.email('nope'), isNotNull));
    test('accepts valid', () {
      expect(Validators.email('jane@example.com'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects short', () => expect(Validators.password('123'), isNotNull));
    test(
      'accepts 6+ chars',
      () => expect(Validators.password('123456'), isNull),
    );
  });

  group('Validators.confirmPassword', () {
    test('rejects mismatch', () {
      expect(Validators.confirmPassword('abc123', 'abc124'), isNotNull);
    });
    test('accepts match', () {
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
    });
  });

  group('Validators.name', () {
    test('rejects empty', () => expect(Validators.name(''), isNotNull));
    test(
      'accepts plain name',
      () => expect(Validators.name('Jane Doe'), isNull),
    );
    test('accepts unicode name', () => expect(Validators.name('Zoë'), isNull));
    test('rejects digits', () => expect(Validators.name('Jane123'), isNotNull));
  });

  group('Validators.phone', () {
    test('optional empty is fine', () => expect(Validators.phone(''), isNull));
    test('required empty fails', () {
      expect(Validators.phone('', required: true), isNotNull);
    });
    test('accepts formatted number', () {
      expect(Validators.phone('+1 (555) 010-1234'), isNull);
    });
  });

  group('Validators.cardExpiry', () {
    test('rejects bad format', () {
      expect(Validators.cardExpiry('13/30'), isNotNull);
    });
    test('rejects past date', () {
      final now = DateTime(2030, 6, 1);
      expect(Validators.cardExpiry('01/30', now: now), isNotNull);
    });
    test('accepts current month', () {
      final now = DateTime(2030, 6, 15);
      expect(Validators.cardExpiry('06/30', now: now), isNull);
    });
  });
}
