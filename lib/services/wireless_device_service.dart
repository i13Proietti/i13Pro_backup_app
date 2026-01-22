import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import '../models/device.dart';

/// Servizio per la gestione dei dispositivi wireless e proximity detection
class WirelessDeviceService {
  final Shell _shell = Shell();
  final _proximityController =
      StreamController<List<WirelessDevice>>.broadcast();
  Timer? _scanTimer;
  final List<WirelessDevice> _discoveredDevices = [];

  Stream<List<WirelessDevice>> get proximityStream =>
      _proximityController.stream;
  List<WirelessDevice> get discoveredDevices => _discoveredDevices;

  /// Avvia la scansione periodica dei dispositivi sulla rete locale
  void startProximityScanning({
    Duration interval = const Duration(seconds: 10),
  }) {
    stopProximityScanning();

    _scanTimer = Timer.periodic(interval, (_) async {
      await _scanLocalNetwork();
    });

    // Scansione iniziale
    _scanLocalNetwork();
  }

  void stopProximityScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  /// Scansiona la rete locale per dispositivi Android con ADB WiFi abilitato
  Future<void> _scanLocalNetwork() async {
    final devices = <WirelessDevice>[];

    try {
      // Ottieni l'IP del computer nella rete locale
      final localIP = await _getLocalIP();
      if (localIP == null) return;

      // Calcola la subnet (es. 192.168.1.x)
      final subnet = localIP.substring(0, localIP.lastIndexOf('.'));

      // Scansiona le porte ADB comuni (5555, 5556) sulla subnet
      // Nota: questa è una scansione base, in produzione usa mDNS/Bonjour
      for (var i = 2; i < 255; i++) {
        final ip = '$subnet.$i';

        // Prova a connettersi ad ADB sulla porta 5555
        final isReachable = await _checkADBConnection(ip, 5555);
        if (isReachable) {
          final device = await _getWirelessDeviceInfo(ip, 5555);
          if (device != null) {
            devices.add(device);
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning network: $e');
    }

    // Aggiorna la lista solo se ci sono cambiamenti
    if (!_areDeviceListsEqual(_discoveredDevices, devices)) {
      _discoveredDevices.clear();
      _discoveredDevices.addAll(devices);
      _proximityController.add(_discoveredDevices);
    }
  }

  /// Ottiene l'indirizzo IP locale del computer
  Future<String?> _getLocalIP() async {
    try {
      // Ottieni l'IP locale
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Cerca IP della rete locale (192.168.x.x o 10.x.x.x)
          final ip = addr.address;
          if (ip.startsWith('192.168.') || ip.startsWith('10.')) {
            return ip;
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting local IP: $e');
    }
    return null;
  }

  /// Verifica se è possibile connettersi ad ADB su un IP specifico
  Future<bool> _checkADBConnection(String ip, int port) async {
    try {
      // Timeout rapido per non bloccare la scansione
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(milliseconds: 500),
      );
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene informazioni sul dispositivo wireless
  Future<WirelessDevice?> _getWirelessDeviceInfo(String ip, int port) async {
    try {
      final address = '$ip:$port';

      // Connetti temporaneamente per ottenere le info
      await _shell.run('adb connect $address');

      // Ottieni le informazioni del dispositivo
      final nameResult = await _shell.run(
        'adb -s $address shell getprop ro.product.model',
      );
      final name = nameResult.first.stdout.toString().trim();

      final versionResult = await _shell.run(
        'adb -s $address shell getprop ro.build.version.release',
      );
      final version = versionResult.first.stdout.toString().trim();

      // Disconnetti temporaneamente
      await _shell.run('adb disconnect $address');

      return WirelessDevice(
        id: address,
        name: name,
        ipAddress: ip,
        port: port,
        osVersion: 'Android $version',
        lastSeen: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error getting wireless device info: $e');
      return null;
    }
  }

  /// Connette a un dispositivo Android via ADB WiFi
  Future<bool> connectWireless(String ip, {int port = 5555}) async {
    try {
      final address = '$ip:$port';
      final result = await _shell.run('adb connect $address');
      final output = result.first.stdout.toString();

      return output.contains('connected') ||
          output.contains('already connected');
    } catch (e) {
      debugPrint('Error connecting wireless: $e');
      return false;
    }
  }

  /// Disconnette da un dispositivo wireless
  Future<void> disconnectWireless(String address) async {
    try {
      await _shell.run('adb disconnect $address');
    } catch (e) {
      debugPrint('Error disconnecting wireless: $e');
    }
  }

  /// Setup iniziale: abilita ADB WiFi su un dispositivo connesso via USB
  Future<String?> setupWirelessADB(String usbDeviceId) async {
    try {
      // Abilita TCP/IP su porta 5555
      await _shell.run('adb -s $usbDeviceId tcpip 5555');

      // Aspetta che il dispositivo riavvii ADB in modalità TCP
      await Future.delayed(const Duration(seconds: 2));

      // Ottieni l'IP del dispositivo
      final ipResult = await _shell.run(
        'adb -s $usbDeviceId shell ip addr show wlan0 | grep "inet " | cut -d\\  -f6 | cut -d/ -f1',
      );
      final ip = ipResult.first.stdout.toString().trim();

      if (ip.isNotEmpty && ip.contains('.')) {
        return ip;
      }
    } catch (e) {
      debugPrint('Error setting up wireless ADB: $e');
    }
    return null;
  }

  bool _areDeviceListsEqual(
    List<WirelessDevice> list1,
    List<WirelessDevice> list2,
  ) {
    if (list1.length != list2.length) return false;
    for (var i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  void dispose() {
    stopProximityScanning();
    _proximityController.close();
  }
}

/// Rappresenta un dispositivo rilevato sulla rete wireless
class WirelessDevice {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final String osVersion;
  final DateTime lastSeen;

  WirelessDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.osVersion,
    required this.lastSeen,
  });

  /// Converte in MobileDevice per compatibilità
  MobileDevice toMobileDevice() {
    return MobileDevice(
      id: id,
      name: name,
      type: DeviceType.android,
      model: name,
      osVersion: osVersion,
      status: DeviceStatus.connected,
    );
  }
}
