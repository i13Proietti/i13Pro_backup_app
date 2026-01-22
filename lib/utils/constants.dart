import 'package:flutter/material.dart';

/// Costanti per percorsi comuni sui dispositivi Android
class AndroidPaths {
  // Foto e Video
  static const dcimCamera = '/sdcard/DCIM/Camera';
  static const dcimScreenshots = '/sdcard/DCIM/Screenshots';
  static const pictures = '/sdcard/Pictures';
  static const movies = '/sdcard/Movies';

  // Documenti
  static const documents = '/sdcard/Documents';
  static const download = '/sdcard/Download';

  // WhatsApp
  static const whatsappImages = '/sdcard/WhatsApp/Media/WhatsApp Images';
  static const whatsappVideo = '/sdcard/WhatsApp/Media/WhatsApp Video';
  static const whatsappAudio = '/sdcard/WhatsApp/Media/WhatsApp Audio';
  static const whatsappDocuments = '/sdcard/WhatsApp/Media/WhatsApp Documents';
  static const whatsappDatabases = '/sdcard/WhatsApp/Databases';

  // Musica
  static const music = '/sdcard/Music';
  static const podcasts = '/sdcard/Podcasts';
  static const ringtones = '/sdcard/Ringtones';
  static const notifications = '/sdcard/Notifications';

  // Altri
  static const alarms = '/sdcard/Alarms';
  static const telegram = '/sdcard/Telegram';

  // Lista di tutti i percorsi comuni
  static List<PathInfo> get allPaths => [
        PathInfo(
          path: dcimCamera,
          name: 'Foto Camera',
          description: 'Foto scattate con la fotocamera',
          icon: Icons.photo_camera,
          category: 'Foto e Video',
        ),
        PathInfo(
          path: dcimScreenshots,
          name: 'Screenshot',
          description: 'Screenshot del dispositivo',
          icon: Icons.screenshot,
          category: 'Foto e Video',
        ),
        PathInfo(
          path: pictures,
          name: 'Immagini',
          description: 'Altre immagini salvate',
          icon: Icons.image,
          category: 'Foto e Video',
        ),
        PathInfo(
          path: movies,
          name: 'Video',
          description: 'Video salvati',
          icon: Icons.video_library,
          category: 'Foto e Video',
        ),
        PathInfo(
          path: documents,
          name: 'Documenti',
          description: 'File e documenti',
          icon: Icons.description,
          category: 'Documenti',
        ),
        PathInfo(
          path: download,
          name: 'Download',
          description: 'File scaricati',
          icon: Icons.download,
          category: 'Documenti',
        ),
        PathInfo(
          path: whatsappImages,
          name: 'WhatsApp Immagini',
          description: 'Immagini ricevute su WhatsApp',
          icon: Icons.chat,
          category: 'WhatsApp',
        ),
        PathInfo(
          path: whatsappVideo,
          name: 'WhatsApp Video',
          description: 'Video ricevuti su WhatsApp',
          icon: Icons.chat,
          category: 'WhatsApp',
        ),
        PathInfo(
          path: whatsappDatabases,
          name: 'WhatsApp Database',
          description: 'Backup chat WhatsApp',
          icon: Icons.chat,
          category: 'WhatsApp',
        ),
        PathInfo(
          path: music,
          name: 'Musica',
          description: 'File musicali',
          icon: Icons.music_note,
          category: 'Audio',
        ),
      ];

  static List<PathInfo> getByCategory(String category) {
    return allPaths.where((path) => path.category == category).toList();
  }

  static List<String> get categories {
    return allPaths.map((p) => p.category).toSet().toList();
  }
}

class PathInfo {
  final String path;
  final String name;
  final String description;
  final IconData icon;
  final String category;

  PathInfo({
    required this.path,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
  });
}

/// Costanti per configurazioni predefinite
class BackupPresets {
  static const photoBackup = 'Backup Foto';
  static const whatsappBackup = 'Backup WhatsApp';
  static const fullBackup = 'Backup Completo';
  static const documentsBackup = 'Backup Documenti';
}

/// Intervalli di backup predefiniti (in minuti)
class BackupIntervals {
  static const every30Minutes = 30;
  static const everyHour = 60;
  static const every6Hours = 360;
  static const every12Hours = 720;
  static const everyDay = 1440;
}
