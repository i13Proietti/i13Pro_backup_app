import 'dart:async';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/backup_config.dart';
import '../models/sync_progress.dart';
import '../services/backup_service.dart';

class BackupProgressDialog extends StatefulWidget {
  final BackupService backupService;
  final MobileDevice device;
  final BackupConfig config;

  const BackupProgressDialog({
    super.key,
    required this.backupService,
    required this.device,
    required this.config,
  });

  @override
  State<BackupProgressDialog> createState() => _BackupProgressDialogState();
}

class _BackupProgressDialogState extends State<BackupProgressDialog> {
  SyncProgress? _progress;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _startBackup();
  }

  void _startBackup() {
    _subscription = widget.backupService.progressStream.listen((progress) {
      setState(() {
        _progress = progress;
      });

      // Chiudi il dialog quando completato o in errore
      if (progress.status == SyncStatus.completed ||
          progress.status == SyncStatus.error) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, progress);
          }
        });
      }
    });

    widget.backupService.startBackup(widget.device, widget.config);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.backup),
          const SizedBox(width: 12),
          const Text('Backup in corso'),
          const Spacer(),
          if (progress?.status == SyncStatus.syncing)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Annulla',
              onPressed: () {
                widget.backupService.cancelBackup();
              },
            ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (progress == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Status
              _StatusRow(progress: progress),
              const SizedBox(height: 16),

              // Progress bar
              if (progress.status == SyncStatus.syncing) ...[
                LinearProgressIndicator(
                  value: progress.progressPercentage / 100,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      progress.progressText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${progress.progressPercentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Current file
              if (progress.currentFile != null) ...[
                Text(
                  'File corrente:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  progress.currentFile!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
              ],

              // Statistics
              _StatsRow(progress: progress),

              // Error message
              if (progress.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          progress.errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (progress?.status == SyncStatus.completed ||
            progress?.status == SyncStatus.error ||
            progress?.status == SyncStatus.cancelled)
          FilledButton(
            onPressed: () => Navigator.pop(context, progress),
            child: const Text('Chiudi'),
          ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final SyncProgress progress;

  const _StatusRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String text;

    switch (progress.status) {
      case SyncStatus.scanning:
        icon = Icons.search;
        color = Colors.blue;
        text = 'Scansione file...';
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.orange;
        text = 'Sincronizzazione...';
        break;
      case SyncStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        text = 'Completato!';
        break;
      case SyncStatus.error:
        icon = Icons.error;
        color = Colors.red;
        text = 'Errore';
        break;
      case SyncStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.grey;
        text = 'Annullato';
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        text = 'In attesa...';
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final SyncProgress progress;

  const _StatsRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.schedule,
            label: 'Tempo',
            value: _formatDuration(progress.elapsedTime),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.speed,
            label: 'Velocità',
            value: progress.speedText,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
