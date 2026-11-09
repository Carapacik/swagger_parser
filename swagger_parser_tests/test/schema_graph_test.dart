@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test('builds cyclic libraries and round-trips finite nested values', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_graph_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String text) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(text);
    }

    Future<void> dart(List<String> args) async {
      final ProcessResult result = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      expect(
        result.exitCode,
        0,
        reason: '${args.join(' ')}\n${result.stdout}\n${result.stderr}',
      );
    }

    final GenerationResult result = await const SwaggerParserRunner().generate(
      await const FileSchemaSourceLoader().loadPath(
        '../swagger_parser/test/fixtures/schema_graphs/large_cycle/graph.json',
      ),
      config: const GenerationConfig(httpClient: HttpClientBackend.dio),
    );
    expect(result.diagnostics, isEmpty);
    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    for (final GeneratedFile file in result.files) {
      await write(file.relativePath, file.content);
    }
    await write('graph_test.dart', '''
import 'dart:convert';
import 'package:test/test.dart';
import 'api.dart';
void main() {
  test('resolves both cycle directions and nullable views', () {
    final wire = <String,Object?>{
      'id':'root',
      'next':{'id':'next','peer':{'id':'root-again'}},
      'peer':{'id':'previous','next':{'id':'root-again'}},
      'shared':{'label':'same'},
    };
    final node = Node0Dto.fromJson(wire);
    expect(node.next, isA<Node1Dto>());
    expect(node.peer, isA<Node1099Dto>());
    expect(node.next!.peer, isA<Node0Dto>());
    expect(jsonDecode(jsonEncode(node)), wire);
    final choice = NullableRootDto.fromJson(wire);
    expect(choice.hasNode0Dto,isTrue);
    expect(choice.asNode0Dto!.id,'root');
    expect(choice.toJson(),wire);
    expect(NullableRootDto.fromJson(null).hasNull,isTrue);
  });
}
''');
    await dart(['analyze', dir.path]);
    await dart(['test', '${dir.path}/graph_test.dart']);
  });
}
