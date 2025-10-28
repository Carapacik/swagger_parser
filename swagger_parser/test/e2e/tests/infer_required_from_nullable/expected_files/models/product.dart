// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@Freezed()
class Product with _$Product {
  const factory Product({
    /// Product ID (not marked nullable, should be required when inferring)
    required int id,

    /// Product Name (not marked nullable, should be required when inferring)
    required String name,

    /// Product Description (marked nullable, should stay optional)
    String? description,

    /// Product Price (marked nullable, should stay optional)
    double? price,
  }) = _Product;

  factory Product.fromJson(Map<String, Object?> json) =>
      _$ProductFromJson(json);
}
