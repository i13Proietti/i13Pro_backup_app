import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../models/device.dart';
import '../models/backup_config.dart';
import '../models/sync_progress.dart';
import 'device_manager.dart';

class BackupService {
  final DeviceManager deviceManager;
  final _progressController = StreamController<SyncProgress>.broadcast();
  bool _isCancelled = false;

  BackupService({required this.deviceManager});

  Stream<SyncProgress> get progressStream => _progressController.stream;

  Future<void> startBackup(MobileDevice device, BackupConfig config) async {
    _isCancelled = false;

    var progress = SyncProgress(
      status: SyncStatus.scanning,
      startTime: DateTime.now(),
    );
    _progressController.add(progress);

    try {
      // Verifica che il dispositivo sia connesso
      if (!await deviceManager.isDeviceConnected(device)) {
        throw Exception('Device not connected');
      }

      // Scansiona i file da backuppare
      final filesToSync = await _scanFiles(device, config);

      progress = progress.copyWith(
        status: SyncStatus.syncing,
        totalFiles: filesToSync.length,
        totalBytes: filesToSync.fold<int>(
          0,
          (sum, file) => sum + (file['size'] as int? ?? 0),
        ),
      );
      _progressController.add(progress);

      // Esegue il backup
      int processedFiles = 0;
      int processedBytes = 0;

      for (var fileInfo in filesToSync) {
        if (_isCancelled) {
          progress = progress.copyWith(
            status: SyncStatus.cancelled,
            endTime: DateTime.now(),
          );
          _progressController.add(progress);
          return;
        }

        final sourcePath = fileInfo['source'] as String;
        final destPath = fileInfo['dest'] as String;
        final fileSize = fileInfo['size'] as int? ?? 0;

        progress = progress.copyWith(currentFile: path.basename(sourcePath));
        _progressController.add(progress);

        try {
          // Sincronizza il file in base alla modalità
          await _syncFile(device, config, sourcePath, destPath);

          processedFiles++;
          processedBytes += fileSize;

          progress = progress.copyWith(
            processedFiles: processedFiles,
            processedBytes: processedBytes,
          );
          _progressController.add(progress);
        } catch (e) {
          debugPrint('Error syncing file $sourcePath: $e');
          // Continua con il prossimo file
        }
      }

      // Gestisci la cancellazione se configurata
      if (config.deleteMode != DeleteMode.none) {
        await _handleDeletion(device, config, filesToSync);
      }

      progress = progress.copyWith(
        status: SyncStatus.completed,
        endTime: DateTime.now(),
      );
      _progressController.add(progress);
    } catch (e) {
      progress = progress.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
        endTime: DateTime.now(),
      );
      _progressController.add(progress);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _scanFiles(
    MobileDevice device,
    BackupConfig config,
  ) async {
    final filesToSync = <Map<String, dynamic>>[];

    for (var folder in config.folders) {
      if (!folder.isEnabled) continue;

      try {
        final files = await _scanFolder(device, folder);
        filesToSync.addAll(files);
      } catch (e) {
        debugPrint('Error scanning folder ${folder.phonePath}: $e');
      }
    }

    return filesToSync;
  }

  Future<List<Map<String, dynamic>>> _scanFolder(
    MobileDevice device,
    BackupFolder folder,
  ) async {
    final files = <Map<String, dynamic>>[];

    try {
      final fileList = await deviceManager.listFiles(device, folder.phonePath);

      for (var fileName in fileList) {
        // Salta cartelle escluse
        if (folder.excludeFolders.contains(fileName)) continue;

        // Salta estensioni escluse
        final extension = path.extension(fileName);
        if (folder.excludeExtensions.contains(extension)) continue;

        final phonePath = '${folder.phonePath}/$fileName';
        final pcPath = path.join(folder.pcPath, fileName);

        try {
          // Ottieni info sul file per determinare se è una directory
          final fileInfo = await deviceManager.getFileInfo(device, phonePath);
          final isDirectory = fileInfo['isDirectory'] as bool? ?? false;
          final fileSize = fileInfo['size'] as int? ?? 0;

          if (isDirectory) {
            // Se è una directory e includiamo sottocartelle, scansiona ricorsivamente
            if (folder.includeSubfolders) {
              final subFolder = BackupFolder(
                id: '${folder.id}_sub',
                phonePath: phonePath,
                pcPath: pcPath,
                includeSubfolders: folder.includeSubfolders,
                excludeExtensions: folder.excludeExtensions,
                excludeFolders: folder.excludeFolders,
                isEnabled: folder.isEnabled,
              );
              final subFiles = await _scanFolder(device, subFolder);
              files.addAll(subFiles);
            }
          } else {
            // È un file normale
            files.add({'source': phonePath, 'dest': pcPath, 'size': fileSize});
          }
        } catch (e) {
          debugPrint('Error getting file info for $phonePath: $e');
          // Se fallisce, assume che sia un file
          files.add({'source': phonePath, 'dest': pcPath, 'size': 0});
        }
      }
    } catch (e) {
      debugPrint('Error scanning folder: $e');
    }

    return files;
  }

  Future<void> _syncFile(
    MobileDevice device,
    BackupConfig config,
    String sourcePath,
    String destPath,
  ) async {
    final destFile = File(destPath);
    final destDir = Directory(path.dirname(destPath));

    // Crea la directory di destinazione se non esiste
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    switch (config.syncMode) {
      case SyncMode.phoneToPC:
        // Copia solo da telefono a PC
        await deviceManager.copyFromDevice(device, sourcePath, destPath);
        break;

      case SyncMode.pcToPhone:
        // Copia solo da PC a telefono
        if (await destFile.exists()) {
          await deviceManager.copyToDevice(device, destPath, sourcePath);
        }
        break;

      case SyncMode.bidirectional:
        // Sincronizzazione bidirezionale
        await _bidirectionalSync(device, sourcePath, destPath);
        break;
    }
  }

  Future<void> _bidirectionalSync(
    MobileDevice device,
    String phonePath,
    String pcPath,
  ) async {
    final pcFile = File(pcPath);
    final pcExists = await pcFile.exists();

    if (!pcExists) {
      // Il file esiste solo sul telefono, copialo sul PC
      await deviceManager.copyFromDevice(device, phonePath, pcPath);
    } else {
      // Entrambi esistono, confronta le date di modifica
      final pcModified = await pcFile.lastModified();

      try {
        // Ottieni la data di modifica del file sul telefono
        final phoneFileInfo = await deviceManager.getFileInfo(
          device,
          phonePath,
        );
        final phoneModified = phoneFileInfo['modified'] as DateTime?;

        if (phoneModified != null) {
          // Confronta i timestamp e sincronizza il più recente
          if (phoneModified.isAfter(pcModified)) {
            // Il file sul telefono è più recente
            await deviceManager.copyFromDevice(device, phonePath, pcPath);
          } else if (pcModified.isAfter(phoneModified)) {
            // Il file sul PC è più recente
            await deviceManager.copyToDevice(device, pcPath, phonePath);
          }
          // Se hanno la stessa data, non fare nulla
        } else {
          // Se non si riesce a ottenere il timestamp, usa strategia semplice
          await deviceManager.copyFromDevice(device, phonePath, pcPath);
        }
      } catch (e) {
        debugPrint('Error in bidirectional sync: $e');
        // Fallback: copia dal telefono al PC
        await deviceManager.copyFromDevice(device, phonePath, pcPath);
      }
    }
  }

  Future<void> _handleDeletion(
    MobileDevice device,
    BackupConfig config,
    List<Map<String, dynamic>> syncedFiles,
  ) async {
    switch (config.deleteMode) {
      case DeleteMode.deleteOnPhone:
        // Cancella i file sul telefono dopo il backup
        for (var fileInfo in syncedFiles) {
          final sourcePath = fileInfo['source'] as String;
          try {
            await deviceManager.deleteOnDevice(device, sourcePath);
          } catch (e) {
            debugPrint('Error deleting file on device: $e');
          }
        }
        break;

      case DeleteMode.deleteOnPC:
        // Cancella i file sul PC
        for (var fileInfo in syncedFiles) {
          final destPath = fileInfo['dest'] as String;
          try {
            final file = File(destPath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            debugPrint('Error deleting file on PC: $e');
          }
        }
        break;

      case DeleteMode.deleteOnBoth:
        // Cancella su entrambi
        for (var fileInfo in syncedFiles) {
          final sourcePath = fileInfo['source'] as String;
          final destPath = fileInfo['dest'] as String;

          try {
            await deviceManager.deleteOnDevice(device, sourcePath);
          } catch (e) {
            debugPrint('Error deleting file on device: $e');
          }

          try {
            final file = File(destPath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            debugPrint('Error deleting file on PC: $e');
          }
        }
        break;

      case DeleteMode.none:
        // Non cancellare nulla
        break;
    }
  }

  void cancelBackup() {
    _isCancelled = true;
  }

  void dispose() {
    _progressController.close();
  }
}
