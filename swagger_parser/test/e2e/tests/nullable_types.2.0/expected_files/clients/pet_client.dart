// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/pet.dart';
import '../models/status.dart';

part 'pet_client.g.dart';

@RestApi()
abstract class PetClient {
  factory PetClient(Dio dio, {String? baseUrl}) = _PetClient;

  /// Add a new pet to the store.
  ///
  /// [body] - Pet object that needs to be added to the store.
  @POST('/pet')
  Future<void> addPet({
    @Body() required Pet body,
  });

  /// Update an existing pet.
  ///
  /// [body] - Pet object that needs to be added to the store.
  @PUT('/pet')
  Future<void> updatePet({
    @Body() required Pet body,
  });

  /// Finds Pets by status.
  ///
  /// Multiple status values can be provided with comma separated strings.
  ///
  /// [status] - Status values that need to be considered for filter.
  @GET('/pet/findByStatus')
  Future<List<Pet>> findPetsByStatus({
    @Query('status') required List<Status> status,
  });

  /// Finds Pets by tags.
  ///
  /// Multiple tags can be provided with comma separated strings. Use tag1, tag2, tag3 for testing.
  ///
  /// [tags] - Tags to filter by.
  @Deprecated('This method is marked as deprecated')
  @GET('/pet/findByTags')
  Future<List<Pet>> findPetsByTags({
    @Query('tags') required List<String> tags,
  });

  /// Find pet by ID.
  ///
  /// Returns a single pet.
  ///
  /// [petId] - ID of pet to return.
  @GET('/pet/{petId}')
  Future<Pet> getPetById({
    @Path('petId') required int petId,
  });

  /// Updates a pet in the store with form data.
  ///
  /// [petId] - ID of pet that needs to be updated.
  ///
  /// [name] - Updated name of the pet.
  ///
  /// [status] - Updated status of the pet.
  @FormUrlEncoded()
  @POST('/pet/{petId}')
  Future<void> updatePetWithForm({
    @Path('petId') required int petId,
    @Part(name: 'name') String? name,
    @Part(name: 'status') String? status,
  });

  /// Deletes a pet.
  ///
  /// [petId] - Pet id to delete.
  @DELETE('/pet/{petId}')
  Future<void> deletePet({
    @Path('petId') required int petId,
    @Header('api_key') String? apiKey,
  });
}
