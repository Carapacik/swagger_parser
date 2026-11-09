import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'preserves unknown fields and coordinates up to depth 128 by default',
    () {
      const config = ParseConfig();
      expect(config.unknownFields, UnknownFieldPolicy.preserve);
      expect(config.captureSourceLocations, isTrue);
      expect(config.maxDepth, 128);
    },
  );

  test('parse uses the constructor config unless replaced by the call', () {
    const constructorConfig = ParseConfig(captureSourceLocations: false);
    const callConfig = ParseConfig();
    final parser = _RecordingParser(config: constructorConfig);
    const source = SchemaSource('{}');

    parser.parse(source);
    expect(parser.receivedConfig, same(constructorConfig));
    parser.parse(source, config: callConfig);
    expect(parser.receivedConfig, same(callConfig));
    expect(parser.receivedConfig.captureSourceLocations, isTrue);
    parser.parse(source);
    expect(parser.receivedConfig, same(constructorConfig));
  });
}

final class _RecordingParser({super.config}) extends OpenApiParser {
  late ParseConfig receivedConfig;

  @override
  OpenApiDocument parseDocument(
    SchemaSource source, {
    required ParseConfig config,
  }) {
    receivedConfig = config;
    return OpenApiV30Document(
      info: OpenApiV30Info(title: 'API', version: '1'),
      paths: OpenApiV30Paths(entries: const {}),
    );
  }
}
