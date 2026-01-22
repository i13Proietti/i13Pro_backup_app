import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/backup_config.dart';
import '../providers/app_state.dart';
import '../services/backup_service.dart';
import 'backup_progress_dialog.dart';

class BackupConfigList extends StatelessWidget {
  final List<BackupConfig> configs;
  final MobileDevice device;

  const BackupConfigList({
    super.key,
    required this.configs,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    if (configs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.backup_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nessuna configurazione',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una nuova configurazione di backup',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: configs.length,
      itemBuilder: (context, index) {
        final config = configs[index];
        return _ConfigCard(config: config, device: device);
      },
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final BackupConfig config;
  final MobileDevice device;

  const _ConfigCard({required this.config, required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${config.folders.length} cartelle configurate',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Elimina configurazione',
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.sync_alt,
                  label: _getSyncModeLabel(config.syncMode),
                  color: Colors.blue,
                ),
                _InfoChip(
                  icon: Icons.delete_sweep,
                  label: _getDeleteModeLabel(config.deleteMode),
                  color: Colors.orange,
                ),
                if (config.autoBackup)
                  _InfoChip(
                    icon: Icons.schedule,
                    label: 'Auto backup',
                    color: Colors.green,
                  ),
              ],
            ),
            if (config.lastBackup != null) ...[
              const SizedBox(height: 12),
              Text(
                'Ultimo backup: ${_formatDate(config.lastBackup!)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to edit screen
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Modifica'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _startBackup(context),
                  icon: const Icon(Icons.backup, size: 18),
                  label: const Text('Avvia Backup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSyncModeLabel(SyncMode mode) {
    switch (mode) {
      case SyncMode.phoneToPC:
        return 'Telefono → PC';
      case SyncMode.pcToPhone:
        return 'PC → Telefono';
      case SyncMode.bidirectional:
        return 'Bidirezionale';
    }
  }

  String _getDeleteModeLabel(DeleteMode mode) {
    switch (mode) {
      case DeleteMode.none:
        return 'Non eliminare';
      case DeleteMode.deleteOnPhone:
        return 'Elimina su telefono';
      case DeleteMode.deleteOnPC:
        return 'Elimina su PC';
      case DeleteMode.deleteOnBoth:
        return 'Elimina su entrambi';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text(
          'Sei sicuro di voler eliminare la configurazione "${config.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AppState>().deleteConfig(config.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _startBackup(BuildContext context) {
    final appState = context.read<AppState>();
    final backupService = BackupService(deviceManager: appState.deviceManager);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackupProgressDialog(
        backupService: backupService,
        device: device,
        config: config,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
