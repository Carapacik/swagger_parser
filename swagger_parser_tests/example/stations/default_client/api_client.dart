import 'dart:convert' as convert;

import 'package:dio/dio.dart'
    show Dio, Options, ResponseType, CancelToken, RequestOptions;
import 'package:retrofit/retrofit.dart'
    show
        RestApi,
        Extras,
        CancelRequest,
        POST,
        GET,
        ParseErrorLogger,
        Body,
        Headers,
        Path,
        Query;

import 'models/station.dart' show Station;

part 'api_client.g.dart';

@RestApi(headers: {'Accept': 'application/json'})
abstract class ApiClient {
  ApiClient._(this._transport);

  factory ApiClient(Dio dio) => _ApiClientWithOptions(dio);

  final Dio _transport;

  Future<Station> _postStationsWithOptions({
    Map<String, Object?> extra = const {
      "openapi.servers": [
        {"url": "https://stations.example/v1"},
      ],
    },
    CancelToken? cancelToken,
    Options? options,
    required Station body,
  }) async {
    final _options = (options ?? Options()).copyWith(
      method: "POST",
      responseType: ResponseType.json,
      extra: {...?options?.extra, ...extra},
      contentType: "application/json",
      headers: {
        for (final entry
            in (options?.headers ?? const <String, Object?>{}).entries)
          if (entry.key.toLowerCase() != 'content-type') entry.key: entry.value,
        'Accept': "application/json",
      },
    );
    final response = await _transport.request<dynamic>(
      "/stations",
      options: _options,
      data: convert.jsonEncode(body),
      cancelToken: cancelToken,
    );
    return Station.fromJson(response.data as Map<String, Object?>);
  }

  @POST('/stations')
  @Headers({'Content-Type': 'application/json'})
  Future<Station> postStations({
    @Extras()
    Map<String, Object?> extra = const {
      "openapi.servers": [
        {"url": "https://stations.example/v1"},
      ],
    },
    @CancelRequest() CancelToken? cancelToken,
    Options? options,
    @Body() required Station body,
  });
  Future<Station> _getStationsByIdWithOptions({
    Map<String, Object?> extra = const {
      "openapi.servers": [
        {"url": "https://stations.example/v1"},
      ],
    },
    CancelToken? cancelToken,
    Options? options,
    required String id,
    List<String>? tag,
  }) async {
    final _options = (options ?? Options()).copyWith(
      method: "GET",
      responseType: ResponseType.json,
      extra: {...?options?.extra, ...extra},
      headers: {...?options?.headers, 'Accept': "application/json"},
    );
    final response = await _transport.request<dynamic>(
      "/stations/" + id.toString(),
      options: _options,
      queryParameters: <String, Object?>{if (tag != null) "tag": tag},
      cancelToken: cancelToken,
    );
    return Station.fromJson(response.data as Map<String, Object?>);
  }

  @GET('/stations/{id}')
  Future<Station> getStationsById({
    @Extras()
    Map<String, Object?> extra = const {
      "openapi.servers": [
        {"url": "https://stations.example/v1"},
      ],
    },
    @CancelRequest() CancelToken? cancelToken,
    Options? options,
    @Path('id') required String id,
    @Query('tag') List<String>? tag,
  });
}

class _ApiClientWithOptions extends _ApiClient {
  _ApiClientWithOptions(Dio dio) : super._(dio, dio);

  @override
  Future<Station> postStations({
    Map<String, Object?> extra = const {
      "openapi.servers": [
        {"url": "https://stations.example/v1"},
      ],
    },
    CancelToken? cancelToken,
    Options? options,
    required Station body,
  }) {
    return options == null
        ? super.postStations(
            extra: extra,
            cancelToken: cancelToken,
            options: options,
            body: body,
          )
        : _postStationsWithOptions(
            extra: extra,
            cancelToken: cancelToken,
            options: options,
            body: body,
          );
  }

  @override
  Future<Station> getStationsById({
    Map<String, Object?> extra = const {
      "openapi.servers": [
        {"url": "https://stations.example/v1"},
      ],
    },
    CancelToken? cancelToken,
    Options? options,
    required String id,
    List<String>? tag,
  }) {
    return options == null
        ? super.getStationsById(
            extra: extra,
            cancelToken: cancelToken,
            options: options,
            id: id,
            tag: tag,
          )
        : _getStationsByIdWithOptions(
            extra: extra,
            cancelToken: cancelToken,
            options: options,
            id: id,
            tag: tag,
          );
  }
}
