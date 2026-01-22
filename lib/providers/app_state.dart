import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/backup_config.dart';
import '../services/device_manager.dart';
import '../services/config_storage.dart';

class AppState extends ChangeNotifier {
  final DeviceManager deviceManager = DeviceManager();
  final ConfigStorage configStorage = ConfigStorage();

  List<MobileDevice> _devices = [];
  List<BackupConfig> _configs = [];
  MobileDevice? _selectedDevice;
  bool _isLoading = false;
  String? _errorMessage;

  List<MobileDevice> get devices => _devices;
  List<BackupConfig> get configs => _configs;
  MobileDevice? get selectedDevice => _selectedDevice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AppState() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Carica le configurazioni salvate
    await loadConfigs();

    // Inizia il polling dei dispositivi
    deviceManager.startDevicePolling();

    // Ascolta i cambiamenti dei dispositivi
    deviceManager.devicesStream.listen((devices) {
      _devices = devices;

      // Se il dispositivo selezionato non è più connesso, deselezionalo
      if (_selectedDevice != null &&
          !devices.any((d) => d.id == _selectedDevice!.id)) {
        _selectedDevice = null;
      }

      notifyListeners();
    });
  }

  Future<void> loadConfigs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _configs = await configStorage.getAllConfigs();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load configurations: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveConfig(BackupConfig config) async {
    try {
      await configStorage.saveConfig(config);
      await loadConfigs();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to save configuration: $e';
      notifyListeners();
    }
  }

  Future<void> deleteConfig(String id) async {
    try {
      await configStorage.deleteConfig(id);
      await loadConfigs();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to delete configuration: $e';
      notifyListeners();
    }
  }

  void selectDevice(MobileDevice? device) {
    _selectedDevice = device;
    notifyListeners();
  }

  List<BackupConfig> getConfigsForSelectedDevice() {
    if (_selectedDevice == null) return [];
    return _configs
        .where((config) => config.deviceId == _selectedDevice!.id)
        .toList();
  }

  @override
  void dispose() {
    deviceManager.dispose();
    super.dispose();
  }
}
