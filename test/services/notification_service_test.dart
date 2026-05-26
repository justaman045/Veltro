import 'package:flutter_test/flutter_test.dart';
import 'package:agentic_todo/services/notification_service.dart';

void main() {
  group('stableId', () {
    test('returns deterministic value for same input', () {
      final id1 = stableId('task-123');
      final id2 = stableId('task-123');
      expect(id1, id2);
    });

    test('returns different values for different inputs', () {
      final id1 = stableId('task-123');
      final id2 = stableId('task-456');
      expect(id1, isNot(id2));
    });

    test('returns non-negative integer', () {
      final id = stableId('any-string');
      expect(id, greaterThanOrEqualTo(0));
    });

    test('handles empty string', () {
      expect(() => stableId(''), returnsNormally);
    });

    test('handles special characters', () {
      expect(() => stableId('hello!@#\$%^&*()'), returnsNormally);
    });
  });
}
