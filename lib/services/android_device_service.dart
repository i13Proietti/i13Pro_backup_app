import 'dart:async';
import 'package:process_run/process_run.dart';
import '../models/device.dart';

abstract class DeviceService {
  Future<List<MobileDevice>> detectDevices();
  Future<bool> isDeviceConnected(String deviceId);
  Future<Map<String, String>> getDeviceInfo(String deviceId);
  Future<List<String>> listFiles(String deviceId, String path);
  Future<void> copyFromDevice(
    String deviceId,
    String sourcePath,
    String destPath,
  );
  Future<void> copyToDevice(
    String deviceId,
    String sourcePath,
    String destPath,
  );
  Future<void> deleteOnDevice(String deviceId, String path);
  Stream<double> getTransferProgress();
}

class AndroidDeviceService implements DeviceService {
  final Shell _shell = Shell();
  final _progressController = StreamController<double>.broadcast();

  // Verifica se ADB è disponibile
  Future<bool> isAdbAvailable() async {
    try {
      final result = await _shell.run('adb version');
      return result.first.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<MobileDevice>> detectDevices() async {
    final devices = <MobileDevice>[];

    try {
      // Esegue adb devices
      final result = await _shell.run('adb devices -l');
      final output = result.first.stdout.toString();
      final lines = output.split('\n');

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty ||
            line.startsWith('List of devices') ||
            !line.contains('device')) {
          continue;
        }

        // Parsing della linea del dispositivo
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 2) continue;

        final deviceId = parts[0];
        final model = _extractProperty(line, 'model:') ?? 'Unknown';
        final device = _extractProperty(line, 'device:') ?? 'Android Device';

        // Ottieni informazioni aggiuntive
        final info = await getDeviceInfo(deviceId);

        devices.add(
          MobileDevice(
            id: deviceId,
            name: info['name'] ?? device,
            type: DeviceType.android,
            model: model,
            osVersion: info['version'] ?? 'Unknown',
            status: DeviceStatus.connected,
            totalStorage: int.tryParse(info['totalStorage'] ?? '0'),
            usedStorage: int.tryParse(info['usedStorage'] ?? '0'),
          ),
        );
      }
    } catch (e) {
      print('Error detecting Android devices: $e');
    }

    return devices;
  }

  String? _extractProperty(String line, String property) {
    final index = line.indexOf(property);
    if (index == -1) return null;

    final start = index + property.length;
    final end = line.indexOf(' ', start);
    if (end == -1) {
      return line.substring(start);
    }
    return line.substring(start, end);
  }

  @override
  Future<bool> isDeviceConnected(String deviceId) async {
    try {
      final devices = await detectDevices();
      return devices.any((device) => device.id == deviceId);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, String>> getDeviceInfo(String deviceId) async {
    final info = <String, String>{};

    try {
      // Nome dispositivo
      final nameResult = await _shell.run(
        'adb -s $deviceId shell getprop ro.product.model',
      );
      info['name'] = nameResult.first.stdout.toString().trim();

      // Versione Android
      final versionResult = await _shell.run(
        'adb -s $deviceId shell getprop ro.build.version.release',
      );
      info['version'] =
          'Android ${versionResult.first.stdout.toString().trim()}';

      // Storage totale (in bytes)
      final storageResult = await _shell.run(
        'adb -s $deviceId shell df /data | tail -1',
      );
      final storageLine = storageResult.first.stdout.toString().trim();
      final storageParts = storageLine.split(RegExp(r'\s+'));
      if (storageParts.length >= 4) {
        info['totalStorage'] = (int.tryParse(storageParts[1]) ?? 0).toString();
        info['usedStorage'] = (int.tryParse(storageParts[2]) ?? 0).toString();
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    return info;
  }

  @override
  Future<List<String>> listFiles(String deviceId, String path) async {
    final files = <String>[];

    try {
      final result = await _shell.run('adb -s $deviceId shell ls -la "$path"');
      final output = result.first.stdout.toString();
      final lines = output.split('\n');

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('total')) continue;

        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 8) {
          final fileName = parts.sublist(7).join(' ');
          if (fileName != '.' && fileName != '..') {
            files.add(fileName);
          }
        }
      }
    } catch (e) {
      print('Error listing files: $e');
    }

    return files;
  }

  @override
  Future<void> copyFromDevice(
    String deviceId,
    String sourcePath,
    String destPath,
  ) async {
    try {
      await _shell.run('adb -s $deviceId pull "$sourcePath" "$destPath"');
    } catch (e) {
      throw Exception('Failed to copy from device: $e');
    }
  }

  @override
  Future<void> copyToDevice(
    String deviceId,
    String sourcePath,
    String destPath,
  ) async {
    try {
      await _shell.run('adb -s $deviceId push "$sourcePath" "$destPath"');
    } catch (e) {
      throw Exception('Failed to copy to device: $e');
    }
  }

  @override
  Future<void> deleteOnDevice(String deviceId, String path) async {
    try {
      await _shell.run('adb -s $deviceId shell rm -rf "$path"');
    } catch (e) {
      throw Exception('Failed to delete on device: $e');
    }
  }

  @override
  Stream<double> getTransferProgress() {
    return _progressController.stream;
  }

  void dispose() {
    _progressController.close();
  }
}
