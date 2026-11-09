part of 'dart_model_mapper.dart';

const Set<String> _typeNames = {
  ...clientTypeNames,
  'models',
  'clients',
  'convert',
  'http',
  'Iterable',
  'Iterator',
  'Record',
  'StringBuffer',
  'Duration',
  'Error',
  'Exception',
  'UnsupportedError',
  'UnimplementedError',
  'Queries',
  'Stream',
  'DateTime',
  'Object',
  'String',
  'List',
  'Map',
  'MapEntry',
  'RegExp',
  'Set',
  'Null',
  'Never',
  'FormatException',
  'ArgumentError',
  'StateError',
  'Type',
  'Enum',
  'Function',
};
const _memberNames = {
  'fromJson',
  'toJson',
  'additionalProperties',
  'hashCode',
  'runtimeType',
  'noSuchMethod',
  'toString',
  'bool',
  'int',
  'num',
  'double',
  'abstract',
  'as',
  'assert',
  'async',
  'augment',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'type',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};

final _word = RegExp('[a-zA-Z0-9]+');

String _identifier(
  String source,
  Set<String> used, {
  bool type = false,
  bool preserveCase = false,
  String ending = '',
  List<String> suffixes = const [],
}) {
  String base = _identifierBase(source, type: type, preserveCase: preserveCase);
  if (base.isEmpty || base.startsWith(RegExp('[0-9]'))) {
    base = '${type ? 'Model' : 'field'}$base';
  }
  base += ending;
  var candidate = base;
  var suffix = 2;
  while (used.contains(candidate) ||
      type && _memberNames.contains(candidate) ||
      suffixes.any((s) => used.contains('$candidate$s'))) {
    candidate = '$base${suffix++}';
  }
  used
    ..add(candidate)
    ..addAll(suffixes.map((suffix) => '$candidate$suffix'));
  return candidate;
}

String _identifierBase(
  String source, {
  bool type = false,
  bool preserveCase = false,
}) {
  final buffer = StringBuffer();
  for (final RegExpMatch match in _word.allMatches(source)) {
    String word = match[0]!;
    if (!preserveCase && word == word.toUpperCase()) {
      word = word.toLowerCase();
    }
    final String first = preserveCase
        ? word[0]
        : type || buffer.isNotEmpty
        ? word[0].toUpperCase()
        : word[0].toLowerCase();
    buffer.write('$first${word.substring(1)}');
  }
  return buffer.toString();
}
