import 'package:swagger_parser_core/src/config/parse_config.dart';
import 'package:swagger_parser_core/src/exceptions/open_api_exception.dart';
import 'package:swagger_parser_core/src/model/json_value.dart';
import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';

/// Reads one value at a JSON Pointer.
typedef ValueParser<T> = T Function(Object? value, String path);

/// Reads required, optional, and extension fields at one pointer.
final class ObjectReader(
  /// Typed readers and error locations for the source document.
  final ReadContext context,
  Object? value,

  /// JSON Pointer to the current object.
  final String path,

  /// Field names recognized on this object.
  final Set<String> known, {
  bool allowExtensions = true,
  bool allowUnknown = false,
}) {
  /// Checks object keys and separates extensions from unknown fields.
  this {
    if (value is! Map<String, Object?>) {
      context.fail('Expected an object.', path);
    }
    fields = value;
    for (final String key in fields.keys) {
      if (known.contains(key)) {
        continue;
      }
      if (allowExtensions && key.startsWith('x-')) {
        extensions[key] = JsonValue(fields[key]);
      } else if (!allowUnknown &&
          context.config.unknownFields == UnknownFieldPolicy.reject) {
        context.fail('Unknown field: $key.', appendPointer(path, key));
      } else {
        extras[key] = JsonValue(fields[key]);
      }
    }
  }

  /// Fields from the decoded object.
  late final Map<String, Object?> fields;

  /// Specification extensions keyed by their `x-` names.
  final extensions = <String, JsonValue>{};

  /// Unrecognized fields kept for export.
  final extras = <String, JsonValue>{};

  /// Reads a required field or reports its missing key.
  T required<T>(String key, ValueParser<T> parse) {
    if (!fields.containsKey(key)) {
      context.fail(
        'Missing required field: $key.',
        appendPointer(path, key),
        parent: path,
      );
    }
    return parse(fields[key], appendPointer(path, key));
  }

  /// Reads a field if present, including explicit null.
  T? optional<T>(String key, ValueParser<T> parse) => fields.containsKey(key)
      ? parse(fields[key], appendPointer(path, key))
      : null;
}

/// Typed readers and diagnostics for one decoded document.
final class const ReadContext(
  /// Decoded input and its source positions.
  final DecodedDocument document,

  /// Options that apply to this document.
  final ParseConfig config,
) {
  /// Associates decoded values with one set of parse options.
  this;

  /// Throws a parse error at the given JSON Pointer.
  Never fail(String message, String path, {String? parent}) =>
      throw SchemaParseException(
        message,
        sourceUri: document.sourceUri,
        documentPath: path,
        location: document.locations[path] ?? document.locations[parent],
      );

  /// Reads a string at the given pointer.
  String string(Object? value, String path) =>
      value is String ? value : fail('Expected a string.', path);

  /// Reads an absolute URI string.
  String absoluteUri(Object? value, String path) {
    final String text = string(value, path);
    final Uri? uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || text.contains(RegExp(r'\s'))) {
      fail('Expected an absolute URI.', path);
    }
    return text;
  }

  /// Reads a boolean at the given pointer.
  bool boolean(Object? value, String path) =>
      value is bool ? value : fail('Expected a boolean.', path);

  /// Reads a finite number.
  num number(Object? value, String path) => value is num && value.isFinite
      ? value
      : fail('Expected a finite number.', path);

  /// Reads a number with an integral value.
  int integer(Object? value, String path) {
    if (value is int) {
      return value;
    }
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    fail('Expected an integer.', path);
  }

  /// Copies the value into immutable JSON data.
  JsonValue jsonValue(Object? value, String path) => JsonValue(value);

  /// Reads each array element with its own pointer.
  List<T> list<T>(Object? value, String path, ValueParser<T> parse) {
    if (value is! List<Object?>) {
      fail('Expected an array.', path);
    }
    return [for (var i = 0; i < value.length; i++) parse(value[i], '$path/$i')];
  }

  /// Reads each object value at the pointer for its key.
  Map<String, T> map<T>(Object? value, String path, ValueParser<T> parse) {
    if (value is! Map<String, Object?>) {
      fail('Expected an object.', path);
    }
    return value.map(
      (key, value) => MapEntry(key, parse(value, appendPointer(path, key))),
    );
  }

  /// Reads an enum value by its source name.
  T enumeration<T extends Enum>(Object? value, String path, List<T> values) {
    final String name = string(value, path);
    for (final option in values) {
      if (option.name == name) {
        return option;
      }
    }
    fail('Unsupported value: $name.', path);
  }
}
