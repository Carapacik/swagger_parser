import 'package:swagger_parser_core/src/model/json_value.dart';
import 'package:swagger_parser_core/src/model/open_api_serialization.dart';
import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';
import 'package:swagger_parser_core/src/parser/object_reader.dart';

/// Named entries and specification extensions from a map.
typedef ParsedEntries<T> = ({
  Map<String, T> entries,
  Map<String, JsonValue> extensions,
});

/// Common field and parameter readers for OpenAPI 3.x.
mixin OpenApi3Reader {
  /// Typed readers and error locations for the source document.
  ReadContext get context;

  static final _componentName = RegExp(r'^[a-zA-Z0-9._-]+$');

  /// Pattern for a response code or uppercase status range.
  static final statusCode = RegExp(r'^[1-5]([0-9]{2}|XX)$');

  /// Returns a reader for a list of typed elements.
  ValueParser<List<T>> listOf<T>(ValueParser<T> parse) =>
      (value, path) => context.list(value, path, parse);

  /// Returns a reader for a map with string keys.
  ValueParser<Map<String, T>> mapOf<T>(ValueParser<T> parse) =>
      (value, path) => context.map(value, path, parse);

  /// Returns a reader for the named enum values.
  ValueParser<T> enumOf<T extends Enum>(List<T> values) =>
      (value, path) => context.enumeration(value, path, values);

  /// Reads named components and checks their keys.
  ValueParser<Map<String, T>> componentsMap<T>(ValueParser<T> parse) =>
      (value, path) {
        final Map<String, Object?> fields = objectFields(value, path);
        for (final String key in fields.keys) {
          if (!_componentName.hasMatch(key)) {
            context.fail('Invalid component name.', appendPointer(path, key));
          }
        }
        return context.map(fields, path, parse);
      };

  /// Reads the string keys and values of a document object.
  Map<String, Object?> objectFields(Object? value, String path) =>
      value is Map<String, Object?>
      ? value
      : context.fail('Expected an object.', path);

  /// Reports a field error using its pointer and available position.
  Never failField(ObjectReader reader, String key, String message) => context
      .fail(message, appendPointer(reader.path, key), parent: reader.path);

  /// Rejects an object that contains both named fields.
  void exclusiveFields(ObjectReader reader, String first, String second) {
    if (reader.fields.containsKey(first) && reader.fields.containsKey(second)) {
      failField(reader, second, 'Use only one of $first and $second.');
    }
  }

  /// Separates named entries from specification extensions.
  ParsedEntries<T> readEntries<T>(
    Object? value,
    String path,
    ValueParser<T> parse, {
    bool Function(String)? validKey,
  }) {
    final entries = <String, T>{};
    final extensions = <String, JsonValue>{};
    for (final MapEntry<String, Object?> entry in objectFields(
      value,
      path,
    ).entries) {
      final String key = entry.key;
      if (key.startsWith('x-')) {
        extensions[key] = JsonValue(entry.value);
        continue;
      }
      final String child = appendPointer(path, key);
      if (validKey != null && !validKey(key)) {
        context.fail('Invalid key: $key.', child);
      }
      entries[key] = parse(entry.value, child);
    }
    return (entries: entries, extensions: extensions);
  }

  /// Checks parameter location and serialization fields.
  void checkParameter(ObjectReader reader, {required bool header}) {
    final OpenApiParameterLocation location = header
        ? OpenApiParameterLocation.header
        : reader.required('in', enumOf(OpenApiParameterLocation.values));
    if (header) {
      for (final key in const ['name', 'in']) {
        if (reader.fields.containsKey(key)) {
          failField(reader, key, 'Header objects cannot set $key.');
        }
      }
    }
    if (location == OpenApiParameterLocation.path &&
        reader.fields['required'] != true) {
      failField(reader, 'required', 'Path parameters require required: true.');
    }
    if (location != OpenApiParameterLocation.query) {
      for (final key in const ['allowEmptyValue', 'allowReserved']) {
        if (reader.fields.containsKey(key)) {
          failField(reader, key, '$key requires a query parameter.');
        }
      }
    }
    exclusiveFields(reader, 'schema', 'content');
    if (reader.fields.containsKey('content')) {
      final Map<String, Object?> content = objectFields(
        reader.fields['content'],
        appendPointer(reader.path, 'content'),
      );
      if (content.length != 1) {
        failField(reader, 'content', 'Expected one media type.');
      }
      for (final key in const [
        'style',
        'explode',
        'allowReserved',
        'example',
        'examples',
      ]) {
        if (reader.fields.containsKey(key)) {
          failField(reader, key, '$key requires schema.');
        }
      }
    } else if (!reader.fields.containsKey('schema')) {
      failField(reader, 'schema', 'Expected schema or content.');
    }
    exclusiveFields(reader, 'example', 'examples');
    checkStyle(reader, location);
  }

  /// Checks that the style supports the parameter location.
  void checkStyle(ObjectReader reader, OpenApiParameterLocation location) {
    final OpenApiParameterStyle? style = reader.optional(
      'style',
      enumOf(OpenApiParameterStyle.values),
    );
    if (style == null) {
      return;
    }
    final Set<OpenApiParameterStyle> valid = switch (location) {
      OpenApiParameterLocation.path => const {
        OpenApiParameterStyle.matrix,
        OpenApiParameterStyle.label,
        OpenApiParameterStyle.simple,
      },
      OpenApiParameterLocation.query => const {
        OpenApiParameterStyle.form,
        OpenApiParameterStyle.spaceDelimited,
        OpenApiParameterStyle.pipeDelimited,
        OpenApiParameterStyle.deepObject,
      },
      OpenApiParameterLocation.header => const {OpenApiParameterStyle.simple},
      OpenApiParameterLocation.cookie => const {OpenApiParameterStyle.form},
    };
    if (!valid.contains(style)) {
      failField(reader, 'style', 'Invalid style for ${location.name}.');
    }
  }
}
