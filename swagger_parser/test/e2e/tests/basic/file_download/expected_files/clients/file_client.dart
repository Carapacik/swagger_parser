// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'file_client.g.dart';

@RestApi()
abstract class FileClient {
  factory FileClient(Dio dio, {String? baseUrl}) = _FileClient;

  /// Download a file
  @GET('/files/{id}')
  @DioResponseType(ResponseType.bytes)
  Future<HttpResponse<List<int>>> downloadFile({
    @Path('id') required String id,
  });
}
