import 'dart:async';
import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import '../models/device.dart';

class IOSDeviceService {
  final Shell _shell = Shell();
  final _progressController = StreamController<double>.broadcast();

  // Verifica se libimobiledevice è disponibile
  Future<bool> isLibimobiledeviceAvailable() async {
    try {
      final result = await _shell.run('idevice_id --version');
      return result.first.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<List<MobileDevice>> detectDevices() async {
    final devices = <MobileDevice>[];

    try {
      // Lista i dispositivi iOS connessi
      final result = await _shell.run('idevice_id -l');
      final output = result.first.stdout.toString();
      final deviceIds = output
          .split('\n')
          .where((id) => id.isNotEmpty)
          .toList();

      for (var deviceId in deviceIds) {
        deviceId = deviceId.trim();
        if (deviceId.isEmpty) continue;

        // Ottieni informazioni sul dispositivo
        final info = await getDeviceInfo(deviceId);

        devices.add(
          MobileDevice(
            id: deviceId,
            name: info['name'] ?? 'iPhone',
            type: DeviceType.ios,
            model: info['model'] ?? 'Unknown',
            osVersion: info['version'] ?? 'Unknown',
            status: DeviceStatus.connected,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error detecting iOS devices: $e');
    }

    return devices;
  }

  Future<bool> isDeviceConnected(String deviceId) async {
    try {
      final devices = await detectDevices();
      return devices.any((device) => device.id == deviceId);
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, String>> getDeviceInfo(String deviceId) async {
    final info = <String, String>{};

    try {
      // Ottieni tutte le informazioni del dispositivo
      final result = await _shell.run('ideviceinfo -u $deviceId');
      final output = result.first.stdout.toString();
      final lines = output.split('\n');

      for (var line in lines) {
        if (line.contains('DeviceName:')) {
          info['name'] = line.split(':').last.trim();
        } else if (line.contains('ProductType:')) {
          info['model'] = line.split(':').last.trim();
        } else if (line.contains('ProductVersion:')) {
          info['version'] = 'iOS ${line.split(':').last.trim()}';
        }
      }
    } catch (e) {
      debugPrint('Error getting iOS device info: $e');
    }

    return info;
  }

  Future<List<String>> listFiles(String deviceId, String path) async {
    final files = <String>[];

    try {
      // Usa ifuse per montare il filesystem iOS
      // Nota: questo richiede che il dispositivo sia stato autorizzato
      // Per iOS è più complesso e richiede l'uso di AFC (Apple File Conduit)
      // Implementazione semplificata
    } catch (e) {
      debugPrint('Error listing iOS files: $e');
    }

    return files;
  }

  Future<void> copyFromDevice(
    String deviceId,
    String sourcePath,
    String destPath,
  ) async {
    try {
      // Usa idevicebackup2 o ifuse per copiare i file
      // Implementazione semplificata
      await _shell.run('idevicebackup2 backup --udid $deviceId "$destPath"');
    } catch (e) {
      throw Exception('Failed to copy from iOS device: $e');
    }
  }

  Future<void> copyToDevice(
    String deviceId,
    String sourcePath,
    String destPath,
  ) async {
    try {
      // iOS ha restrizioni severe sulla scrittura dei file
      // Potrebbe essere necessario usare AFC2 (richiede jailbreak) o limitarsi
      // alle directory consentite come Documents
      throw UnimplementedError(
        'Copying to iOS devices requires special permissions',
      );
    } catch (e) {
      throw Exception('Failed to copy to iOS device: $e');
    }
  }

  Future<void> deleteOnDevice(String deviceId, String path) async {
    throw UnimplementedError(
      'Deleting files on iOS devices is restricted by Apple',
    );
  }

  Future<Map<String, dynamic>> getFileInfo(String deviceId, String path) async {
    final info = <String, dynamic>{};

    try {
      // iOS ha restrizioni, per ora ritorna info di default
      info['size'] = 0;
      info['isDirectory'] = false;
      info['modified'] = DateTime.now();
    } catch (e) {
      debugPrint('Error getting iOS file info: $e');
    }

    return info;
  }

  Stream<double> getTransferProgress() {
    return _progressController.stream;
  }

  void dispose() {
    _progressController.close();
  }
}
