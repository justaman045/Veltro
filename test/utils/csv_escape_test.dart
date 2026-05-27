import 'package:flutter_test/flutter_test.dart';
import 'package:agentic_todo/utils/csv_export.dart';

void main() {
  group('csvEscape', () {
    test('wraps normal string in quotes', () {
      expect(csvEscape('hello'), '"hello"');
    });

    test('escapes double quotes by doubling them', () {
      expect(csvEscape('say "hello"'), '"say ""hello"""');
    });

    test('strips leading =', () {
      expect(csvEscape('=SUM(A1:A10)'), '"SUM(A1:A10)"');
    });

    test('strips leading +', () {
      expect(csvEscape('+cmd'), '"cmd"');
    });

    test('strips leading -', () {
      expect(csvEscape('-1+2'), '"1+2"');
    });

    test('strips leading @', () {
      expect(csvEscape('@domain.com'), '"domain.com"');
    });

    test('does not prefix = in middle of string', () => expect(csvEscape('a=b'), '"a=b"'));

    test('does not prefix + in middle of string', () => expect(csvEscape('1+1'), '"1+1"'));

    test('empty string returns empty quotes', () {
      expect(csvEscape(''), '""');
    });

    test('handles special characters', () {
      expect(csvEscape('hello, world'), '"hello, world"');
    });

    test('handles newlines inside value', () {
      expect(csvEscape('line1\nline2'), '"line1\nline2"');
    });
  });
}
