import 'dart:convert';

import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

void main() {
  // Accepted flags for schema-based parameters in the official JSON Schemas.
  const reserved = {
    '3.0.0': {'query', 'path', 'cookie', 'header', 'Header Object'},
    '3.0.4': {'query', 'path', 'cookie', 'header', 'Header Object'},
    '3.1.2': {'query'},
    '3.2.1': {'query', 'path', 'cookie', 'cookie/form'},
  };
  for (final String version in reserved.keys) {
    for (final flag in ['allowEmptyValue', 'allowReserved']) {
      test('validates $flag against the OpenAPI $version schema', () {
        for (final site in [
          'query',
          'path',
          'cookie',
          'header',
          'Header Object',
          if (version == '3.2.1') ...[
            'cookie/form',
            'cookie/cookie',
            'querystring',
          ],
        ]) {
          for (final content in [false, true]) {
            if (!content && site == 'querystring') {
              continue;
            }
            for (final Object value in [true, false, 'true']) {
              final header = site == 'Header Object';
              final section = header ? 'headers' : 'parameters';
              final Map<String, Object> data = {
                'openapi': version,
                'info': {'title': 'Items', 'version': '1'},
                'paths': <String, Object?>{},
                'components': {
                  section: {
                    'Item': {
                      if (!header) ...{
                        'name': 'id',
                        'in': site.split('/').first,
                      },
                      if (site == 'path') 'required': true,
                      if (!content && site.contains('/'))
                        'style': site.split('/').last,
                      if (content)
                        'content': {'text/plain': <String, Object?>{}}
                      else
                        'schema': {'type': 'string'},
                      flag: value,
                    },
                  },
                },
              };
              final bool allowed =
                  value is bool &&
                  (flag == 'allowReserved'
                      ? !content && reserved[version]!.contains(site)
                      : version.startsWith('3.0.') || site == 'query');
              OpenApiDocument parse() => const OpenApiParser().parse(
                SchemaSource.json(jsonEncode(data)),
                config: const ParseConfig(
                  unknownFields: UnknownFieldPolicy.reject,
                ),
              );
              final reason = '$site, content=$content, $flag=$value';
              if (allowed) {
                expect(parse().toJson(), data, reason: reason);
              } else {
                expect(
                  parse,
                  throwsA(
                    isA<SchemaParseException>().having(
                      (error) => error.documentPath,
                      'field',
                      '/components/$section/Item/$flag',
                    ),
                  ),
                  reason: reason,
                );
              }
            }
          }
        }
      });
    }
  }
}
