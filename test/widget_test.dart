import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App smoke test', () {
    test('trivial math works', () {
      expect(1 + 1, equals(2));
    });

    test('string operations', () {
      expect('hello'.toUpperCase(), 'HELLO');
    });
  });
}
