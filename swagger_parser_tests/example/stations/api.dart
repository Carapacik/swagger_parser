import 'package:dio/dio.dart' as transport;

import 'exports.dart' as clients show ApiClient;

export 'exports.dart';

final class Api {
  /// API title from info.title.
  static const String title = "Stations";

  /// API version from info.version.
  static const String apiVersion = "1";

  /// Exact Swagger or OpenAPI version.
  static const String specVersion = "3.2.1";

  Api(this._client);
  final transport.Dio _client;

  late final clients.ApiClient api = clients.ApiClient(_client);
}
