import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';

/// Checks each codec with Dio and each transport with plain DTOs.
/// Serializer/client tests retain the full cross-product.
bool isFocusedConsumer(DtoSerializer serializer, HttpClientBackend backend) =>
    serializer == DtoSerializer.plain || backend == HttpClientBackend.dio;

/// Groups generated test libraries into one compiler entry point.
Future<String> groupConsumerTests(Directory directory) async {
  final List<File> drivers = await directory
      .list()
      .where((file) => file is File && file.path.endsWith('_test.dart'))
      .cast<File>()
      .toList();
  drivers.sort((a, b) => a.path.compareTo(b.path));
  if (drivers.isEmpty) {
    throw StateError('No consumer tests found.');
  }
  final names = <String>[];
  for (final driver in drivers) {
    final String name = driver.uri.pathSegments.last.replaceFirst(
      '_test.dart',
      '_checks.dart',
    );
    await driver.rename('${directory.path}/$name');
    names.add(name);
  }
  final file = File('${directory.path}/checks_test.dart');
  await file.writeAsString(
    [
      "import 'package:test/test.dart';",
      for (final (i, name) in names.indexed) "import '$name' as check$i;",
      'void main() {',
      for (final (i, name) in names.indexed) "group('$name', check$i.main);",
      '}',
    ].join('\n'),
  );
  return file.path;
}
