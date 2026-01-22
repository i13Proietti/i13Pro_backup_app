import 'package:json_annotation/json_annotation.dart';

part 'backup_config.g.dart';

enum SyncMode {
  bidirectional, // Sincronizzazione bidirezionale
  phoneToPC, // Solo da telefono a PC
  pcToPhone, // Solo da PC a telefono
}

enum DeleteMode {
  none, // Non cancellare nulla
  deleteOnPhone, // Cancella solo sul telefono
  deleteOnPC, // Cancella solo sul PC
  deleteOnBoth, // Cancella su entrambi
}

@JsonSerializable()
class BackupFolder {
  final String id;
  final String phonePath;
  final String pcPath;
  final bool includeSubfolders;
  final List<String> excludeExtensions;
  final List<String> excludeFolders;
  bool isEnabled;

  BackupFolder({
    required this.id,
    required this.phonePath,
    required this.pcPath,
    this.includeSubfolders = true,
    this.excludeExtensions = const [],
    this.excludeFolders = const [],
    this.isEnabled = true,
  });

  factory BackupFolder.fromJson(Map<String, dynamic> json) =>
      _$BackupFolderFromJson(json);

  Map<String, dynamic> toJson() => _$BackupFolderToJson(this);
}

@JsonSerializable()
class BackupConfig {
  final String id;
  final String deviceId;
  final String name;
  final List<BackupFolder> folders;
  final SyncMode syncMode;
  final DeleteMode deleteMode;
  final bool autoBackup;
  final int? scheduleIntervalMinutes;
  DateTime? lastBackup;
  DateTime createdAt;
  DateTime updatedAt;

  BackupConfig({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.folders,
    this.syncMode = SyncMode.phoneToPC,
    this.deleteMode = DeleteMode.none,
    this.autoBackup = false,
    this.scheduleIntervalMinutes,
    this.lastBackup,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory BackupConfig.fromJson(Map<String, dynamic> json) =>
      _$BackupConfigFromJson(json);

  Map<String, dynamic> toJson() => _$BackupConfigToJson(this);

  BackupConfig copyWith({
    String? id,
    String? deviceId,
    String? name,
    List<BackupFolder>? folders,
    SyncMode? syncMode,
    DeleteMode? deleteMode,
    bool? autoBackup,
    int? scheduleIntervalMinutes,
    DateTime? lastBackup,
    DateTime? updatedAt,
  }) {
    return BackupConfig(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      folders: folders ?? this.folders,
      syncMode: syncMode ?? this.syncMode,
      deleteMode: deleteMode ?? this.deleteMode,
      autoBackup: autoBackup ?? this.autoBackup,
      scheduleIntervalMinutes:
          scheduleIntervalMinutes ?? this.scheduleIntervalMinutes,
      lastBackup: lastBackup ?? this.lastBackup,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
