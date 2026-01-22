enum SyncStatus { idle, scanning, syncing, completed, error, cancelled }

class SyncProgress {
  final SyncStatus status;
  final int totalFiles;
  final int processedFiles;
  final int totalBytes;
  final int processedBytes;
  final String? currentFile;
  final String? errorMessage;
  final DateTime startTime;
  DateTime? endTime;

  SyncProgress({
    required this.status,
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.totalBytes = 0,
    this.processedBytes = 0,
    this.currentFile,
    this.errorMessage,
    DateTime? startTime,
    this.endTime,
  }) : startTime = startTime ?? DateTime.now();

  double get progressPercentage {
    if (totalFiles == 0) return 0.0;
    return (processedFiles / totalFiles) * 100;
  }

  String get progressText {
    return '$processedFiles / $totalFiles files';
  }

  String get speedText {
    if (endTime == null && status == SyncStatus.syncing) {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      if (elapsed > 0 && processedBytes > 0) {
        final bytesPerSecond = processedBytes / elapsed;
        final mbPerSecond = bytesPerSecond / (1024 * 1024);
        return '${mbPerSecond.toStringAsFixed(2)} MB/s';
      }
    }
    return 'N/A';
  }

  Duration get elapsedTime {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  SyncProgress copyWith({
    SyncStatus? status,
    int? totalFiles,
    int? processedFiles,
    int? totalBytes,
    int? processedBytes,
    String? currentFile,
    String? errorMessage,
    DateTime? endTime,
  }) {
    return SyncProgress(
      status: status ?? this.status,
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      totalBytes: totalBytes ?? this.totalBytes,
      processedBytes: processedBytes ?? this.processedBytes,
      currentFile: currentFile ?? this.currentFile,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
