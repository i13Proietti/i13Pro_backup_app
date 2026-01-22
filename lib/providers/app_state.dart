import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/backup_config.dart';
import '../services/device_manager.dart';
import '../services/config_storage.dart';
import '../services/wireless_device_service.dart';
import '../services/proximity_backup_service.dart';

class AppState extends ChangeNotifier {
  final DeviceManager deviceManager = DeviceManager();
  final ConfigStorage configStorage = ConfigStorage();
  final WirelessDeviceService wirelessService = WirelessDeviceService();
  late final ProximityBackupService proximityBackupService;

  List<MobileDevice> _devices = [];
  List<BackupConfig> _configs = [];
  MobileDevice? _selectedDevice;
  bool _isLoading = false;
  String? _errorMessage;
  bool _proximityBackupEnabled = false;
  List<WirelessDevice> _wirelessDevices = [];

  List<MobileDevice> get devices => _devices;
  List<BackupConfig> get configs => _configs;
  MobileDevice? get selectedDevice => _selectedDevice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get proximityBackupEnabled => _proximityBackupEnabled;
  List<WirelessDevice> get wirelessDevices => _wirelessDevices;

  AppState() {
    // Inizializza il servizio di proximity backup
    proximityBackupService = ProximityBackupService(
      wirelessService: wirelessService,
      deviceManager: deviceManager,
      configStorage: configStorage,
    );

    _initialize();
  }

  Future<void> _initialize() async {
    // Carica le configurazioni salvate
    await loadConfigs();

    // Inizia il polling dei dispositivi USB
    deviceManager.startDevicePolling();

    // Ascolta i cambiamenti dei dispositivi USB
    deviceManager.devicesStream.listen((devices) {
      _devices = devices;

      // Se il dispositivo selezionato non è più connesso, deselezionalo
      if (_selectedDevice != null &&
          !devices.any((d) => d.id == _selectedDevice!.id)) {
        _selectedDevice = null;
      }

      notifyListeners();
    });

    // Ascolta i dispositivi wireless rilevati
    wirelessService.proximityStream.listen((wirelessDevices) {
      _wirelessDevices = wirelessDevices;
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

  /// Abilita/disabilita il proximity backup
  void toggleProximityBackup(bool enabled) {
    _proximityBackupEnabled = enabled;

    if (enabled) {
      proximityBackupService.startProximityBackup();
    } else {
      proximityBackupService.stopProximityBackup();
    }

    notifyListeners();
  }

  /// Setup iniziale del wireless ADB per un dispositivo USB
  Future<String?> setupWirelessConnection(MobileDevice device) async {
    try {
      final ip = await wirelessService.setupWirelessADB(device.id);
      if (ip != null) {
        // Avvia la scansione per rilevare il dispositivo
        wirelessService.startProximityScanning();
      }
      return ip;
    } catch (e) {
      _errorMessage = 'Failed to setup wireless: $e';
      notifyListeners();
      return null;
    }
  }

  /// Connette manualmente a un dispositivo wireless
  Future<bool> connectToWirelessDevice(String ip, {int port = 5555}) async {
    try {
      return await wirelessService.connectWireless(ip, port: port);
    } catch (e) {
      _errorMessage = 'Failed to connect wireless: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    deviceManager.dispose();
    wirelessService.dispose();
    proximityBackupService.dispose();
    super.dispose();
  }
}
