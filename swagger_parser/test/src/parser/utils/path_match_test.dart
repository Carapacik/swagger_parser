import 'package:swagger_parser/src/parser/utils/path_match.dart';
import 'package:test/test.dart';

void main() {
  group('matchesPathPattern', () {
    test('exact match without wildcards', () {
      expect(matchesPathPattern('/api/users', ['/api/users']), isTrue);
      expect(matchesPathPattern('/api/users/profile', ['/api/users/profile']), isTrue);
      expect(matchesPathPattern('/exact/path/{id}', ['/exact/path/{id}']), isTrue);
    });

    test('no match for different paths', () {
      expect(matchesPathPattern('/api/users', ['/api/posts']), isFalse);
      expect(matchesPathPattern('/api/users/profile', ['/api/users/settings']), isFalse);
    });

    test('single asterisk wildcard (*)', () {
      // Basic single segment match
      expect(matchesPathPattern('/users/123/update', ['/users/*/update']), isTrue);
      expect(matchesPathPattern('/api/v1/users', ['/api/*/users']), isTrue);

      // No match when path has more segments
      expect(matchesPathPattern('/users/123/profile/update', ['/users/*/update']), isFalse);
      expect(matchesPathPattern('/api/v1/extra/users', ['/api/*/users']), isFalse);

      // Match at different positions
      expect(matchesPathPattern('/users/123', ['/users/*']), isTrue);
      expect(matchesPathPattern('/api/123/endpoint', ['/api/*/endpoint']), isTrue);
    });

    test('double asterisk wildcard (**) - long path', () {
      expect(matchesPathPattern('/api/service/loyalty/balance/history', ['/api/service/loyalty/**']), isTrue);
    });

    test('double asterisk wildcard (**) - another', () {
      expect(matchesPathPattern('/another/wildcard/long/path', ['/another/wildcard/**']), isTrue);
    });

    test('double asterisk wildcard (**) - parts', () {
      expect(matchesPathPattern('path/with/several/parts', ['path/**/parts']), isTrue);
    });

    test('double asterisk wildcard (**) - single', () {
      expect(matchesPathPattern('/api/single', ['/api/**']), isTrue);
    });

    test('double asterisk wildcard (**) - wildcard', () {
      expect(matchesPathPattern('wildcard/path', ['wildcard/**']), isTrue);
    });

    test('double asterisk wildcard (**) - empty', () {
      expect(matchesPathPattern('/api', ['/api/**']), isTrue);
    });

    test('multiple patterns', () {
      expect(matchesPathPattern('/users/123/update', ['/posts/*/create', '/users/*/update']), isTrue);
      expect(matchesPathPattern('/api/v1/users', ['/api/v2/users', '/api/v1/*']), isTrue);
      expect(matchesPathPattern('/api/service/loyalty/balance', ['/api/*/loyalty', '/api/service/**']), isTrue);
    });

    test('special regex characters in paths', () {
      // Dots in paths
      expect(matchesPathPattern('/api/v1.0/users', ['/api/*/users']), isTrue);
      expect(matchesPathPattern('/files/document.pdf', ['/files/*']), isTrue);

      // Plus signs
      expect(matchesPathPattern('/api/v1+users', ['/api/*']), isTrue);

      // Parentheses
      expect(matchesPathPattern('/api(v1)', ['/*']), isTrue);
    });

    test('empty and edge cases', () {
      // Empty patterns list should not match
      expect(matchesPathPattern('/any/path', []), isFalse);

      // Empty path
      expect(matchesPathPattern('', ['']), isTrue);
      expect(matchesPathPattern('', ['*']), isFalse); // * requires at least one non-slash char
      expect(matchesPathPattern('', ['**']), isTrue);

      // Root path
      expect(matchesPathPattern('/', ['/']), isTrue);
      expect(matchesPathPattern('/', ['/*']), isFalse);
    });

    test('complex patterns', () {
      // Mixed wildcards
      expect(matchesPathPattern('/api/v1/users/123/posts/456/comments', ['/api/*/users/*/posts/**']), isTrue);
      expect(matchesPathPattern('/users/123/profile/settings/advanced', ['/users/*/profile/**']), isTrue);

      // Wildcard at start (matches one segment)
      expect(matchesPathPattern('/dynamic/endpoint', ['*/endpoint']), isTrue);
      expect(matchesPathPattern('/some/deep/path/endpoint', ['**/endpoint']), isTrue);
    });

    test('no match cases', () {
      // Different structure
      expect(matchesPathPattern('/users/123/update', ['/posts/*/create']), isFalse);
      expect(matchesPathPattern('/api/v1/users', ['/api/v2/*']), isFalse);

      // Too many segments for single *
      expect(matchesPathPattern('/api/deep/nested/path', ['/api/*']), isFalse);
      expect(matchesPathPattern('/users/123/profile/update', ['/users/*/update']), isFalse);

      // Insufficient segments for **
      expect(matchesPathPattern('/api', ['/api/**/endpoint']), isFalse);
    });
  });
}
