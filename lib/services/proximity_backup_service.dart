import 'dart:async';
import 'package:flutter/material.dart';

import '../models/backup_config.dart';
import 'wireless_device_service.dart';
import 'backup_service.dart';
import 'device_manager.dart';
import 'config_storage.dart';

/// Servizio per il backup automatico basato sulla prossimità
class ProximityBackupService {
  final WirelessDeviceService wirelessService;
  final DeviceManager deviceManager;
  final ConfigStorage configStorage;

  final Map<String, Timer> _backupCooldowns = {};
  final Map<String, bool> _isBackingUp = {};

  bool _isEnabled = false;
  Duration cooldownPeriod = const Duration(minutes: 30);

  ProximityBackupService({
    required this.wirelessService,
    required this.deviceManager,
    required this.configStorage,
  });

  /// Avvia il monitoraggio della prossimità per backup automatici
  void startProximityBackup() {
    if (_isEnabled) return;

    _isEnabled = true;

    // Avvia la scansione wireless
    wirelessService.startProximityScanning(
      interval: const Duration(seconds: 15),
    );

    // Ascolta i dispositivi rilevati
    wirelessService.proximityStream.listen((wirelessDevices) {
      _onDevicesDetected(wirelessDevices);
    });
  }

  void stopProximityBackup() {
    _isEnabled = false;
    wirelessService.stopProximityScanning();
    _backupCooldowns.clear();
    _isBackingUp.clear();
  }

  /// Chiamato quando vengono rilevati dispositivi sulla rete
  Future<void> _onDevicesDetected(List<WirelessDevice> wirelessDevices) async {
    if (!_isEnabled) return;

    for (var wirelessDevice in wirelessDevices) {
      final deviceId = wirelessDevice.id;

      // Salta se è già in corso un backup per questo dispositivo
      if (_isBackingUp[deviceId] == true) continue;

      // Salta se siamo nel periodo di cooldown
      if (_isInCooldown(deviceId)) continue;

      // Ottieni le configurazioni con proximity backup abilitato
      final configs = await _getProximityConfigs(deviceId);

      if (configs.isEmpty) continue;

      // Avvia il backup automatico
      await _startAutomaticBackup(wirelessDevice, configs);
    }
  }

  /// Verifica se il dispositivo è nel periodo di cooldown
  bool _isInCooldown(String deviceId) {
    final timer = _backupCooldowns[deviceId];
    return timer != null && timer.isActive;
  }

  /// Ottiene le configurazioni con proximity backup abilitato
  Future<List<BackupConfig>> _getProximityConfigs(String deviceId) async {
    try {
      final allConfigs = await configStorage.getAllConfigs();

      return allConfigs.where((config) {
        // Filtra per device ID e proximity backup abilitato
        return config.deviceId == deviceId &&
            config.autoBackup == true &&
            config.scheduleIntervalMinutes != null;
      }).toList();
    } catch (e) {
      debugPrint('Error getting proximity configs: $e');
      return [];
    }
  }

  /// Avvia il backup automatico per un dispositivo
  Future<void> _startAutomaticBackup(
    WirelessDevice wirelessDevice,
    List<BackupConfig> configs,
  ) async {
    final deviceId = wirelessDevice.id;

    try {
      debugPrint('📡 Dispositivo rilevato: ${wirelessDevice.name}');
      debugPrint('🔄 Avvio backup automatico...');

      _isBackingUp[deviceId] = true;

      // Connetti al dispositivo wireless
      final connected = await wirelessService.connectWireless(
        wirelessDevice.ipAddress,
        port: wirelessDevice.port,
      );

      if (!connected) {
        debugPrint('❌ Impossibile connettersi a ${wirelessDevice.name}');
        _isBackingUp[deviceId] = false;
        return;
      }

      // Converte in MobileDevice
      final mobileDevice = wirelessDevice.toMobileDevice();

      // Esegui il backup per ogni configurazione
      for (var config in configs) {
        try {
          debugPrint('💾 Backup: ${config.name}');

          final backupService = BackupService(deviceManager: deviceManager);
          await backupService.startBackup(mobileDevice, config);

          // Aggiorna l'ultimo backup
          final updatedConfig = config.copyWith(
            lastBackup: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await configStorage.saveConfig(updatedConfig);

          debugPrint('✅ Backup completato: ${config.name}');
        } catch (e) {
          debugPrint('❌ Errore backup ${config.name}: $e');
        }
      }

      // Imposta il cooldown
      _setCooldown(deviceId);

      debugPrint('🎉 Backup automatico completato per ${wirelessDevice.name}');
    } catch (e) {
      debugPrint('❌ Errore durante backup automatico: $e');
    } finally {
      _isBackingUp[deviceId] = false;

      // Disconnetti il dispositivo wireless
      await wirelessService.disconnectWireless(wirelessDevice.id);
    }
  }

  /// Imposta il periodo di cooldown per evitare backup troppo frequenti
  void _setCooldown(String deviceId) {
    // Cancella il timer esistente se presente
    _backupCooldowns[deviceId]?.cancel();

    // Crea nuovo timer di cooldown
    _backupCooldowns[deviceId] = Timer(cooldownPeriod, () {
      _backupCooldowns.remove(deviceId);
    });
  }

  /// Ottiene lo stato del proximity backup per un dispositivo
  Future<ProximityBackupStatus> getStatus(String deviceId) async {
    final configs = await _getProximityConfigs(deviceId);

    return ProximityBackupStatus(
      isEnabled: _isEnabled && configs.isNotEmpty,
      isBackingUp: _isBackingUp[deviceId] ?? false,
      isInCooldown: _isInCooldown(deviceId),
      configCount: configs.length,
      lastBackup: configs.isNotEmpty ? configs.first.lastBackup : null,
    );
  }

  void dispose() {
    stopProximityBackup();
    for (var timer in _backupCooldowns.values) {
      timer.cancel();
    }
    _backupCooldowns.clear();
  }
}

/// Stato del proximity backup
class ProximityBackupStatus {
  final bool isEnabled;
  final bool isBackingUp;
  final bool isInCooldown;
  final int configCount;
  final DateTime? lastBackup;

  ProximityBackupStatus({
    required this.isEnabled,
    required this.isBackingUp,
    required this.isInCooldown,
    required this.configCount,
    this.lastBackup,
  });

  String get statusText {
    if (!isEnabled) return 'Proximity backup disabilitato';
    if (isBackingUp) return 'Backup in corso...';
    if (isInCooldown) return 'In attesa (cooldown)';
    return 'In ascolto per dispositivi vicini';
  }
}
