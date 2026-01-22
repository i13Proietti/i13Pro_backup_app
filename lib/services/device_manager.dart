import 'dart:async';
import '../models/device.dart';
import 'android_device_service.dart';
import 'ios_device_service.dart';

class DeviceManager {
  final AndroidDeviceService _androidService = AndroidDeviceService();
  final IOSDeviceService _iosService = IOSDeviceService();

  final _devicesController = StreamController<List<MobileDevice>>.broadcast();
  Timer? _pollTimer;
  List<MobileDevice> _lastDevices = [];

  Stream<List<MobileDevice>> get devicesStream => _devicesController.stream;
  List<MobileDevice> get currentDevices => _lastDevices;

  // Inizia il polling per rilevare dispositivi
  void startDevicePolling({Duration interval = const Duration(seconds: 3)}) {
    stopDevicePolling();

    _pollTimer = Timer.periodic(interval, (_) async {
      await refreshDevices();
    });

    // Refresh iniziale
    refreshDevices();
  }

  void stopDevicePolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refreshDevices() async {
    final devices = await detectAllDevices();

    // Aggiorna solo se ci sono cambiamenti
    if (!_areDeviceListsEqual(_lastDevices, devices)) {
      _lastDevices = devices;
      _devicesController.add(devices);
    }
  }

  bool _areDeviceListsEqual(
    List<MobileDevice> list1,
    List<MobileDevice> list2,
  ) {
    if (list1.length != list2.length) return false;

    for (var i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id || list1[i].status != list2[i].status) {
        return false;
      }
    }

    return true;
  }

  Future<List<MobileDevice>> detectAllDevices() async {
    final devices = <MobileDevice>[];

    try {
      // Rileva dispositivi Android
      if (await _androidService.isAdbAvailable()) {
        final androidDevices = await _androidService.detectDevices();
        devices.addAll(androidDevices);
      }

      // Rileva dispositivi iOS
      if (await _iosService.isLibimobiledeviceAvailable()) {
        final iosDevices = await _iosService.detectDevices();
        devices.addAll(iosDevices);
      }
    } catch (e) {
      print('Error detecting devices: $e');
    }

    return devices;
  }

  Future<bool> isDeviceConnected(MobileDevice device) async {
    switch (device.type) {
      case DeviceType.android:
        return await _androidService.isDeviceConnected(device.id);
      case DeviceType.ios:
        return await _iosService.isDeviceConnected(device.id);
      default:
        return false;
    }
  }

  Future<List<String>> listFiles(MobileDevice device, String path) async {
    switch (device.type) {
      case DeviceType.android:
        return await _androidService.listFiles(device.id, path);
      case DeviceType.ios:
        return await _iosService.listFiles(device.id, path);
      default:
        return [];
    }
  }

  Future<void> copyFromDevice(
    MobileDevice device,
    String sourcePath,
    String destPath,
  ) async {
    switch (device.type) {
      case DeviceType.android:
        await _androidService.copyFromDevice(device.id, sourcePath, destPath);
        break;
      case DeviceType.ios:
        await _iosService.copyFromDevice(device.id, sourcePath, destPath);
        break;
      default:
        throw Exception('Unsupported device type');
    }
  }

  Future<void> copyToDevice(
    MobileDevice device,
    String sourcePath,
    String destPath,
  ) async {
    switch (device.type) {
      case DeviceType.android:
        await _androidService.copyToDevice(device.id, sourcePath, destPath);
        break;
      case DeviceType.ios:
        await _iosService.copyToDevice(device.id, sourcePath, destPath);
        break;
      default:
        throw Exception('Unsupported device type');
    }
  }

  Future<void> deleteOnDevice(MobileDevice device, String path) async {
    switch (device.type) {
      case DeviceType.android:
        await _androidService.deleteOnDevice(device.id, path);
        break;
      case DeviceType.ios:
        await _iosService.deleteOnDevice(device.id, path);
        break;
      default:
        throw Exception('Unsupported device type');
    }
  }

  void dispose() {
    stopDevicePolling();
    _devicesController.close();
    _androidService.dispose();
    _iosService.dispose();
  }
}
