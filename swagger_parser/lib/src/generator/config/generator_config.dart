import '../../parser/model/replacement_rule.dart';
import '../model/json_serializer.dart';
import '../model/programming_language.dart';

/// The configuration that the Generator uses
class GeneratorConfig {
  /// Creates a  [GeneratorConfig].
  const GeneratorConfig({
    required this.name,
    required this.outputDirectory,
    this.language = ProgrammingLanguage.dart,
    this.jsonSerializer = JsonSerializer.jsonSerializable,
    this.defaultContentType = 'application/json',
    this.rootClient = true,
    this.extrasParameterByDefault = false,
    this.dioOptionsParameterByDefault = false,
    this.rootClientName = 'RestClient',
    this.clientPostfix,
    this.exportFile = true,
    this.putClientsInFolder = false,
    this.enumsToJson = false,
    this.unknownEnumValue = true,
    this.markFilesAsGenerated = false,
    this.originalHttpResponse = false,
    this.replacementRules = const [],
    this.generateValidator = false,
    this.useFreezed3 = false,
    this.useMultipartFile = false,
    this.fallbackUnion,
    this.mergeOutputs = false,
  });

  /// Optional. Set API name for folder and export file or merged output file
  /// If not specified, the file name is used.
  final String name;

  /// Required. Sets output directory for generated files (Clients and DTOs).
  final String outputDirectory;

  /// Optional. Sets the programming language.
  /// Current available languages are: dart, kotlin.
  final ProgrammingLanguage language;

  /// DART ONLY
  /// Optional. Current available serializers are: json_serializable, freezed, dart_mappable.
  final JsonSerializer jsonSerializer;

  /// Optional. Set postfix for client classes and files.
  final String? clientPostfix;

  /// DART ONLY
  /// Optional. Set 'true' to generate root client
  /// with interface and all clients instances.
  final bool rootClient;

  /// DART ONLY
  /// Optional. Set root client name.
  final String? rootClientName;

  /// DART ONLY
  /// Optional. Set `true` to generate export file.
  final bool exportFile;

  /// Optional. Set `true` to put all clients in clients folder.
  final bool putClientsInFolder;

  /// DART ONLY
  /// Optional. Set `true` to include toJson() in enums.
  /// If set to `false`, serialization will use .name instead.
  final bool enumsToJson;

  /// DART ONLY
  /// Optional. Set `true` to maintain backwards compatibility when adding new values on the backend.
  final bool unknownEnumValue;

  /// Optional. Set `false` to not put a comment at the beginning of the generated files.
  final bool markFilesAsGenerated;

  /// DART ONLY
  /// Optional. Set `true` to wrap all request return types with HttpResponse.
  final bool originalHttpResponse;

  /// DART ONLY
  /// Default content type for all requests and responses.
  ///
  /// If the content type does not match the default, generates:
  /// `@Headers(<String, String>{'Content-Type': 'PARSED CONTENT TYPE'})`
  final String defaultContentType;

  /// DART ONLY
  /// Add extra parameter to all requests. Supported after retrofit 4.1.0.
  ///
  /// If  value is 'true', then the annotation will be added to all requests.
  /// ```dart
  /// @POST('/path/')
  /// Future<String> myMethod({@Extras() Map<String, dynamic>? extras});
  /// ```
  final bool extrasParameterByDefault;

  /// DART ONLY
  /// Add dio options parameter to all requests.
  ///
  /// If  value is 'true', then the annotation will be added to all requests.
  /// ```dart
  /// @POST('/path/')
  /// Future<String> myMethod({@DioOptions() RequestOptions? options});
  /// ```
  final bool dioOptionsParameterByDefault;

  /// Optional. Set regex replacement rules for the names of the generated classes/enums.
  /// All rules are applied in order.
  final List<ReplacementRule> replacementRules;

  /// Optional. Set `true` to generate validator function and prams for freezed.
  final bool generateValidator;

  /// Optional. Set `true` to use freezed v3 if jsonSerializer is freezed.
  final bool useFreezed3;

  /// DART ONLY
  /// Optional. Set `true` to use MultipartFile instead of File as argument type
  /// for file parameters.
  final bool useMultipartFile;

  /// DART ONLY
  /// Optional. Set fallback constructor name to use fallbackUnion parameter when using Freezed annotation.
  final String? fallbackUnion;

  /// Optional. Set to true to merge all generated code into a single file.
  ///
  /// This is useful when using swagger_parser together with build_runner, which needs to map
  /// input files to output files 1-to-1.
  final bool mergeOutputs;
}
