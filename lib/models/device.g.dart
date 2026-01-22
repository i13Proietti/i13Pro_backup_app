// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MobileDevice _$MobileDeviceFromJson(Map<String, dynamic> json) => MobileDevice(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$DeviceTypeEnumMap, json['type']),
  model: json['model'] as String,
  osVersion: json['osVersion'] as String,
  status:
      $enumDecodeNullable(_$DeviceStatusEnumMap, json['status']) ??
      DeviceStatus.disconnected,
  lastSync: json['lastSync'] == null
      ? null
      : DateTime.parse(json['lastSync'] as String),
  totalStorage: (json['totalStorage'] as num?)?.toInt(),
  usedStorage: (json['usedStorage'] as num?)?.toInt(),
);

Map<String, dynamic> _$MobileDeviceToJson(MobileDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$DeviceTypeEnumMap[instance.type]!,
      'model': instance.model,
      'osVersion': instance.osVersion,
      'status': _$DeviceStatusEnumMap[instance.status]!,
      'lastSync': instance.lastSync?.toIso8601String(),
      'totalStorage': instance.totalStorage,
      'usedStorage': instance.usedStorage,
    };

const _$DeviceTypeEnumMap = {
  DeviceType.android: 'android',
  DeviceType.ios: 'ios',
  DeviceType.unknown: 'unknown',
};

const _$DeviceStatusEnumMap = {
  DeviceStatus.connected: 'connected',
  DeviceStatus.disconnected: 'disconnected',
  DeviceStatus.syncing: 'syncing',
  DeviceStatus.error: 'error',
};
