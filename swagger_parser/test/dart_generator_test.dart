import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test('renders required, nullable and optional fields as formatted Dart', () {
    final GenerationResult result = const DartGenerator().generate(
      DartGenerationModel(libraries: [_userLibrary()]),
    );

    expect(result.files.single.relativePath, 'models/user.dart');
    expect(result.files.single.content, '''
class User {
  const User({required this.id, required this.alias, this.name});

  final int id;

  final String? alias;

  final String? name;
}
''');
    expect(result.diagnostics, isEmpty);
  });

  test('imports are scoped independently for every file and invocation', () {
    const generator = DartGenerator();
    final external = DartLibraryModel(
      relativePath: 'models/envelope.dart',
      dtos: [
        DartDtoModel(
          name: 'Envelope',
          fields: [
            DartFieldModel(
              name: 'items',
              type: DartTypeReference(
                symbol: 'List',
                typeArguments: [
                  DartTypeReference(
                    symbol: 'User',
                    importUrl: 'package:example/user.dart',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
    final model = DartGenerationModel(libraries: [_userLibrary(), external]);
    final GenerationResult first = generator.generate(model);
    final GenerationResult second = generator.generate(model);

    expect(first.files.map((file) => file.relativePath), [
      'models/envelope.dart',
      'models/user.dart',
    ]);
    expect(
      first.files.first.content,
      contains("import 'package:example/user.dart'"),
    );
    expect(first.files.first.content, contains('List<_i1.User>'));
    expect(first.files.last.content, isNot(contains('import ')));
    expect(
      first.files.map((file) => file.content),
      second.files.map((file) => file.content),
    );
  });

  test('rejects duplicate output paths before rendering', () {
    expect(
      () => const DartGenerator().generate(
        DartGenerationModel(libraries: [_userLibrary(), _userLibrary()]),
      ),
      throwsArgumentError,
    );
  });

  test('rejects unsafe archive paths', () {
    for (final path in [
      '',
      '/user.dart',
      '../user.dart',
      'a/../user.dart',
      r'a\user.dart',
      'C:/user.dart',
      'a//user.dart',
      './user.dart',
      'a\u0000.dart',
    ]) {
      expect(
        () => GeneratedFile(relativePath: path, content: ''),
        throwsArgumentError,
        reason: path,
      );
    }
  });

  test('results and model collections are snapshots', () {
    final List<DartLibraryModel> libraries = [_userLibrary()];
    final model = DartGenerationModel(libraries: libraries);
    libraries.clear();
    final GenerationResult result = const DartGenerator().generate(model);
    expect(result.files, hasLength(1));
    expect(result.files.clear, throwsUnsupportedError);
    expect(model.libraries.clear, throwsUnsupportedError);
  });
}

DartLibraryModel _userLibrary() => DartLibraryModel(
  relativePath: 'models/user.dart',
  dtos: [
    DartDtoModel(
      name: 'User',
      fields: [
        DartFieldModel(
          name: 'id',
          type: DartTypeReference(symbol: 'int'),
        ),
        DartFieldModel(
          name: 'alias',
          type: DartTypeReference(symbol: 'String', isNullable: true),
        ),
        DartFieldModel(
          name: 'name',
          type: DartTypeReference(symbol: 'String', isNullable: true),
          isRequired: false,
        ),
      ],
    ),
  ],
);
