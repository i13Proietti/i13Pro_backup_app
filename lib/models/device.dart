import 'package:json_annotation/json_annotation.dart';

part 'device.g.dart';

enum DeviceType { android, ios, unknown }

enum DeviceStatus { connected, disconnected, syncing, error }

@JsonSerializable()
class MobileDevice {
  final String id;
  final String name;
  final DeviceType type;
  final String model;
  final String osVersion;
  DeviceStatus status;
  DateTime? lastSync;
  int? totalStorage;
  int? usedStorage;

  MobileDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.model,
    required this.osVersion,
    this.status = DeviceStatus.disconnected,
    this.lastSync,
    this.totalStorage,
    this.usedStorage,
  });

  factory MobileDevice.fromJson(Map<String, dynamic> json) =>
      _$MobileDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$MobileDeviceToJson(this);

  String get storageInfo {
    if (totalStorage == null || usedStorage == null) return 'N/A';
    final total = (totalStorage! / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final used = (usedStorage! / (1024 * 1024 * 1024)).toStringAsFixed(1);
    return '$used GB / $total GB';
  }

  double get storagePercentage {
    if (totalStorage == null || usedStorage == null || totalStorage == 0) {
      return 0.0;
    }
    return (usedStorage! / totalStorage!) * 100;
  }
}
