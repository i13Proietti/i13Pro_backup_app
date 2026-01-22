import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/backup_config.dart';

class ConfigStorage {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Inizializza FFI per desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(appDir.path, 'i13pro_backup.db');

    _database = await openDatabase(dbPath, version: 1, onCreate: _onCreate);

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE backup_configs (
        id TEXT PRIMARY KEY,
        device_id TEXT NOT NULL,
        name TEXT NOT NULL,
        folders TEXT NOT NULL,
        sync_mode TEXT NOT NULL,
        delete_mode TEXT NOT NULL,
        auto_backup INTEGER NOT NULL,
        schedule_interval_minutes INTEGER,
        last_backup TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> saveConfig(BackupConfig config) async {
    final db = await database;

    await db.insert('backup_configs', {
      'id': config.id,
      'device_id': config.deviceId,
      'name': config.name,
      'folders': jsonEncode(config.folders.map((f) => f.toJson()).toList()),
      'sync_mode': config.syncMode.name,
      'delete_mode': config.deleteMode.name,
      'auto_backup': config.autoBackup ? 1 : 0,
      'schedule_interval_minutes': config.scheduleIntervalMinutes,
      'last_backup': config.lastBackup?.toIso8601String(),
      'created_at': config.createdAt.toIso8601String(),
      'updated_at': config.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateConfig(BackupConfig config) async {
    await saveConfig(config.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteConfig(String id) async {
    final db = await database;
    await db.delete('backup_configs', where: 'id = ?', whereArgs: [id]);
  }

  Future<BackupConfig?> getConfig(String id) async {
    final db = await database;
    final maps = await db.query(
      'backup_configs',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToConfig(maps.first);
  }

  Future<List<BackupConfig>> getAllConfigs() async {
    final db = await database;
    final maps = await db.query('backup_configs');
    return maps.map(_mapToConfig).toList();
  }

  Future<List<BackupConfig>> getConfigsForDevice(String deviceId) async {
    final db = await database;
    final maps = await db.query(
      'backup_configs',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
    return maps.map(_mapToConfig).toList();
  }

  BackupConfig _mapToConfig(Map<String, dynamic> map) {
    final foldersJson = jsonDecode(map['folders'] as String) as List;
    final folders = foldersJson
        .map((json) => BackupFolder.fromJson(json as Map<String, dynamic>))
        .toList();

    return BackupConfig(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      name: map['name'] as String,
      folders: folders,
      syncMode: SyncMode.values.firstWhere(
        (e) => e.name == map['sync_mode'],
        orElse: () => SyncMode.phoneToPC,
      ),
      deleteMode: DeleteMode.values.firstWhere(
        (e) => e.name == map['delete_mode'],
        orElse: () => DeleteMode.none,
      ),
      autoBackup: map['auto_backup'] == 1,
      scheduleIntervalMinutes: map['schedule_interval_minutes'] as int?,
      lastBackup: map['last_backup'] != null
          ? DateTime.parse(map['last_backup'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
