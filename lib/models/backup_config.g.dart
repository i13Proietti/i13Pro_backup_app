// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BackupFolder _$BackupFolderFromJson(Map<String, dynamic> json) => BackupFolder(
  id: json['id'] as String,
  phonePath: json['phonePath'] as String,
  pcPath: json['pcPath'] as String,
  includeSubfolders: json['includeSubfolders'] as bool? ?? true,
  excludeExtensions:
      (json['excludeExtensions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  excludeFolders:
      (json['excludeFolders'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  isEnabled: json['isEnabled'] as bool? ?? true,
);

Map<String, dynamic> _$BackupFolderToJson(BackupFolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phonePath': instance.phonePath,
      'pcPath': instance.pcPath,
      'includeSubfolders': instance.includeSubfolders,
      'excludeExtensions': instance.excludeExtensions,
      'excludeFolders': instance.excludeFolders,
      'isEnabled': instance.isEnabled,
    };

BackupConfig _$BackupConfigFromJson(Map<String, dynamic> json) => BackupConfig(
  id: json['id'] as String,
  deviceId: json['deviceId'] as String,
  name: json['name'] as String,
  folders: (json['folders'] as List<dynamic>)
      .map((e) => BackupFolder.fromJson(e as Map<String, dynamic>))
      .toList(),
  syncMode:
      $enumDecodeNullable(_$SyncModeEnumMap, json['syncMode']) ??
      SyncMode.phoneToPC,
  deleteMode:
      $enumDecodeNullable(_$DeleteModeEnumMap, json['deleteMode']) ??
      DeleteMode.none,
  autoBackup: json['autoBackup'] as bool? ?? false,
  scheduleIntervalMinutes: (json['scheduleIntervalMinutes'] as num?)?.toInt(),
  lastBackup: json['lastBackup'] == null
      ? null
      : DateTime.parse(json['lastBackup'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$BackupConfigToJson(BackupConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'name': instance.name,
      'folders': instance.folders,
      'syncMode': _$SyncModeEnumMap[instance.syncMode]!,
      'deleteMode': _$DeleteModeEnumMap[instance.deleteMode]!,
      'autoBackup': instance.autoBackup,
      'scheduleIntervalMinutes': instance.scheduleIntervalMinutes,
      'lastBackup': instance.lastBackup?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$SyncModeEnumMap = {
  SyncMode.bidirectional: 'bidirectional',
  SyncMode.phoneToPC: 'phoneToPC',
  SyncMode.pcToPhone: 'pcToPhone',
};

const _$DeleteModeEnumMap = {
  DeleteMode.none: 'none',
  DeleteMode.deleteOnPhone: 'deleteOnPhone',
  DeleteMode.deleteOnPC: 'deleteOnPC',
  DeleteMode.deleteOnBoth: 'deleteOnBoth',
};
