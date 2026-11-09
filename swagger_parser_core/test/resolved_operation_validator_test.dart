import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

import 'support/read_input.dart';

final Uri _base = Uri.parse('https://stations.example/validation/');

class _FixtureLoader() implements DocumentLoader {
  @override
  Future<SchemaSource> load(Uri uri) async =>
      SchemaSource(await readInput(uri.pathSegments.join('/')), uri: uri);
}

Future<ValidationReport> _validate(String name) async {
  final loader = _FixtureLoader();
  final SchemaSource source = await loader.load(_base.resolve(name));
  final OpenApiDocument document = const OpenApiParser().parse(source);
  expect(const OpenApiValidator().validate(document).diagnostics, isEmpty);
  final ReferenceGraph graph = await const OpenApiReferenceResolver().resolve(
    document,
    sourceUri: source.uri,
    loader: loader,
  );
  return const ResolvedOperationValidator().validate(document, graph);
}

void main() {
  test(
    'inherits parameters across files and applies local overrides',
    () async {
      expect((await _validate('valid.yaml')).diagnostics, isEmpty);
    },
  );

  test(
    'checks mounted operations at their physical source locations',
    () async {
      final ValidationReport report = await _validate('invalid.json');
      final Uri root = _base.resolve('invalid.json');
      final Uri items = _base.resolve('shared/paths.yaml');
      final Uri library = _base.resolve('shared/library.json');
      expect(
        report.diagnostics.map((d) => (d.code, d.sourceUri, d.documentPath)),
        unorderedEquals([
          ('unusedPathParameter', items, '/Broken/parameters/0'),
          ('duplicateOperationId', items, '/Broken/get/operationId'),
          ('missingPathParameter', items, '/Broken/get'),
          ('missingPathParameter', items, '/StationGroup'),
          (
            'invalidParameter',
            _base.resolve('shared/parameters.json'),
            '/unnamed',
          ),
          (
            'duplicateParameter',
            items,
            '/Broken/additionalOperations/REPORT/parameters/1',
          ),
          (
            'duplicateParameter',
            items,
            '/Broken/additionalOperations/REPORT/parameters/3',
          ),
          ('missingPathParameter', root, '/paths/~1audit~1{id}/post'),
          (
            'optionalPathParameter',
            _base.resolve('shared/parameters.json'),
            '/optional/required',
          ),
          (
            'duplicateOperationId',
            library,
            '/components/pathItems/Hook/post/operationId',
          ),
        ]),
      );
    },
  );

  test(
    'checks each mount and follows external callbacks and webhooks',
    () async {
      final ValidationReport report = await _validate('reuse.yaml');
      final Iterable<Diagnostic> ids = report.diagnostics.where(
        (d) => d.code == 'duplicateOperationId',
      );
      expect(
        ids.map((d) => d.documentPath),
        unorderedEquals([
          '/ById/get/operationId',
          '/components/pathItems/Hook/post/operationId',
        ]),
      );
      expect(ids.first.message, contains('/paths/~1primary~1{id}/get'));
      expect(ids.first.message, contains('/paths/~1secondary~1{code}/get'));
      expect(ids.last.message, contains('/callbacks/alarm/'));
      expect(ids.last.message, contains('/webhooks/alarm/post'));
      final Iterable<Diagnostic> parameters = report.diagnostics.where(
        (d) => d.code != 'duplicateOperationId',
      );
      expect(
        parameters.map((d) => (d.code, d.documentPath)),
        unorderedEquals([
          ('missingPathParameter', '/ById/get'),
          ('unusedPathParameter', '/ById/parameters/0'),
        ]),
      );
      for (final error in parameters) {
        expect(error.message, contains('/secondary/{code}'));
      }
    },
  );

  test(
    'stops reference cycles and reports a parameter without a definition',
    () async {
      final ValidationReport report = await _validate('cycles.yaml');
      final Diagnostic error = report.diagnostics.single;
      expect(error.code, 'unresolvedParameter');
      expect(error.sourceUri, _base.resolve('cycles.yaml'));
      expect(error.documentPath, r'/paths/~1tree~1{id}/get/parameters/0/$ref');
    },
  );

  test('checks Swagger 2.0 routes from an external YAML Path Item', () async {
    final ValidationReport report = await _validate('swagger_v2.json');
    expect(
      report.diagnostics.map((d) => (d.code, d.sourceUri, d.documentPath)),
      unorderedEquals([
        (
          'missingPathParameter',
          _base.resolve('../references/paths.yaml'),
          '/pets/get',
        ),
        (
          'duplicateOperationId',
          _base.resolve('swagger_v2.json'),
          '/paths/~1list/get/operationId',
        ),
      ]),
    );
  });

  test('uses the target OpenAPI family for external operations', () async {
    final ValidationReport report = await _validate('mixed_versions.yaml');
    final Diagnostic error = report.diagnostics.single;
    expect(error.code, 'duplicateOperationId');
    expect(error.sourceUri, _base.resolve('shared/paths.yaml'));
    expect(error.documentPath, '/Station/query/operationId');
  });
}
