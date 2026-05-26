import 'package:flutter_test/flutter_test.dart';
import 'package:agentic_todo/models/time_task.dart';
import 'package:agentic_todo/services/ai_service.dart';

void main() {
  group('aiParsePriority', () {
    test('maps urgent to high', () {
      expect(aiParsePriority('urgent'), TaskPriority.high);
    });

    test('maps high to high', () {
      expect(aiParsePriority('high'), TaskPriority.high);
    });

    test('maps medium to medium', () {
      expect(aiParsePriority('medium'), TaskPriority.medium);
    });

    test('maps low to low', () {
      expect(aiParsePriority('low'), TaskPriority.low);
    });

    test('defaults to medium for unknown', () {
      expect(aiParsePriority('critical'), TaskPriority.medium);
    });

    test('defaults to medium for null', () {
      expect(aiParsePriority(null), TaskPriority.medium);
    });

    test('case insensitive', () {
      expect(aiParsePriority('URGENT'), TaskPriority.high);
      expect(aiParsePriority('High'), TaskPriority.high);
      expect(aiParsePriority('LOW'), TaskPriority.low);
    });
  });

  group('aiParseCategory', () {
    test('maps growth to other', () {
      expect(aiParseCategory('growth'), TaskCategory.other);
    });

    test('maps work to work', () {
      expect(aiParseCategory('work'), TaskCategory.work);
    });

    test('maps health to health', () {
      expect(aiParseCategory('health'), TaskCategory.health);
    });

    test('maps finance to finance', () {
      expect(aiParseCategory('finance'), TaskCategory.finance);
    });

    test('maps personal to personal', () {
      expect(aiParseCategory('personal'), TaskCategory.personal);
    });

    test('defaults to other for unknown', () {
      expect(aiParseCategory('hobby'), TaskCategory.other);
    });

    test('defaults to other for null', () {
      expect(aiParseCategory(null), TaskCategory.other);
    });

    test('case insensitive', () {
      expect(aiParseCategory('Work'), TaskCategory.work);
      expect(aiParseCategory('GROWTH'), TaskCategory.other);
    });
  });
}
