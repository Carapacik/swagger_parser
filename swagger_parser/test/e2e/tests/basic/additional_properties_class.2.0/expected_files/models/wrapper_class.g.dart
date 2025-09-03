// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrapper_class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WrapperClass _$WrapperClassFromJson(Map<String, dynamic> json) =>
    _WrapperClass(
      map: (json['map'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, ValueClass.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$WrapperClassToJson(_WrapperClass instance) =>
    <String, dynamic>{
      'map': instance.map,
    };
