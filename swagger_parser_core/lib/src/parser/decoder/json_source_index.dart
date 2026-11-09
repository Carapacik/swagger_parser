part of 'source_decoder.dart';

/// Indexes JSON tokens after dart:convert has checked the syntax.
final class _JsonSourceIndex(
  final SchemaSource source,
  final ParseConfig config,
) {
  final locations = <String, SourceLocation>{};
  late final _file = spans.SourceFile.fromString(
    source.content,
    url: source.uri,
  );
  int _offset = 0;
  String get _text => source.content;

  DecodedDocument index(Object? value) {
    _visit('', 0);
    return DecodedDocument(value, locations, source.uri);
  }

  SourceLocation _at(int offset) {
    final spans.SourceLocation location = _file.location(offset);
    return SourceLocation(
      line: location.line + 1,
      column: location.column + 1,
      offset: offset,
    );
  }

  Never _fail(String message, String path, int offset) =>
      throw SchemaParseException(
        message,
        documentPath: path,
        sourceUri: source.uri,
        location: config.captureSourceLocations ? _at(offset) : null,
      );

  void _visit(String path, int depth) {
    _skipSpace();
    if (depth > config.maxDepth) {
      _fail('Maximum nesting depth exceeded.', path, _offset);
    }
    if (config.captureSourceLocations) {
      locations[path] = _at(_offset);
    }
    switch (_text[_offset]) {
      case '{':
        _object(path, depth);
      case '[':
        _array(path, depth);
      case '"':
        _skipString();
      default:
        final int start = _offset;
        while (_offset < _text.length &&
            _text.codeUnitAt(_offset) > 32 &&
            !',]}'.contains(_text[_offset])) {
          _offset++;
        }
        final int first = _text.codeUnitAt(start);
        if ((first == 45 || (first >= 48 && first <= 57)) &&
            !num.parse(_text.substring(start, _offset)).isFinite) {
          _fail('Expected a finite JSON value.', path, start);
        }
    }
  }

  void _object(String path, int depth) {
    final keys = <String>{};
    _offset++;
    _skipSpace();
    while (_text[_offset] != '}') {
      final int start = _offset;
      _skipString();
      final key = jsonDecode(_text.substring(start, _offset)) as String;
      final String child = appendPointer(path, key);
      if (!keys.add(key)) {
        _fail('Duplicate object key: $key.', child, start);
      }
      _skipSpace();
      _offset++; // Colon.
      _visit(child, depth + 1);
      _skipSpace();
      if (_text[_offset] == ',') {
        _offset++;
        _skipSpace();
      }
    }
    _offset++;
  }

  void _array(String path, int depth) {
    _offset++;
    _skipSpace();
    var index = 0;
    while (_text[_offset] != ']') {
      _visit('$path/$index', depth + 1);
      index++;
      _skipSpace();
      if (_text[_offset] == ',') {
        _offset++;
        _skipSpace();
      }
    }
    _offset++;
  }

  void _skipSpace() {
    while (_offset < _text.length && _text.codeUnitAt(_offset) <= 32) {
      _offset++;
    }
  }

  void _skipString() {
    _offset++;
    while (_text[_offset] != '"') {
      if (_text.codeUnitAt(_offset) == 92) {
        _offset++;
      }
      _offset++;
    }
    _offset++;
  }
}
