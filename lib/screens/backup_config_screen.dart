import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/device.dart';
import '../models/backup_config.dart';
import '../providers/app_state.dart';

class BackupConfigScreen extends StatefulWidget {
  final MobileDevice device;
  final BackupConfig? existingConfig;

  const BackupConfigScreen({
    super.key,
    required this.device,
    this.existingConfig,
  });

  @override
  State<BackupConfigScreen> createState() => _BackupConfigScreenState();
}

class _BackupConfigScreenState extends State<BackupConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final List<BackupFolder> _folders = [];
  SyncMode _syncMode = SyncMode.phoneToPC;
  DeleteMode _deleteMode = DeleteMode.none;
  bool _autoBackup = false;
  int? _scheduleInterval;

  @override
  void initState() {
    super.initState();

    if (widget.existingConfig != null) {
      _nameController.text = widget.existingConfig!.name;
      _folders.addAll(widget.existingConfig!.folders);
      _syncMode = widget.existingConfig!.syncMode;
      _deleteMode = widget.existingConfig!.deleteMode;
      _autoBackup = widget.existingConfig!.autoBackup;
      _scheduleInterval = widget.existingConfig!.scheduleIntervalMinutes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingConfig == null
              ? 'Nuova Configurazione'
              : 'Modifica Configurazione',
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveConfiguration,
            icon: const Icon(Icons.save),
            label: const Text('Salva'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Informazioni dispositivo
            _DeviceInfo(device: widget.device),
            const SizedBox(height: 24),

            // Nome configurazione
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome Configurazione',
                hintText: 'Es: Backup Foto e Video',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci un nome per la configurazione';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Cartelle da backuppare
            _FoldersSection(
              folders: _folders,
              onAdd: _addFolder,
              onRemove: _removeFolder,
            ),
            const SizedBox(height: 24),

            // Modalità di sincronizzazione
            _SyncModeSection(
              syncMode: _syncMode,
              onChanged: (mode) => setState(() => _syncMode = mode),
            ),
            const SizedBox(height: 24),

            // Modalità di cancellazione
            _DeleteModeSection(
              deleteMode: _deleteMode,
              onChanged: (mode) => setState(() => _deleteMode = mode),
            ),
            const SizedBox(height: 24),

            // Backup automatico
            _AutoBackupSection(
              autoBackup: _autoBackup,
              scheduleInterval: _scheduleInterval,
              onAutoBackupChanged: (value) =>
                  setState(() => _autoBackup = value),
              onIntervalChanged: (value) =>
                  setState(() => _scheduleInterval = value),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFolder() async {
    // Seleziona la cartella del telefono (manualmente per ora)
    final phonePathController = TextEditingController();

    // Seleziona la cartella del PC
    final pcPath = await FilePicker.platform.getDirectoryPath();

    if (pcPath == null) return;

    if (!mounted) return;

    final result = await showDialog<BackupFolder>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi Cartella'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phonePathController,
              decoration: const InputDecoration(
                labelText: 'Percorso sul telefono',
                hintText: '/sdcard/DCIM/Camera',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Percorso PC: $pcPath'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              if (phonePathController.text.isNotEmpty) {
                final folder = BackupFolder(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  phonePath: phonePathController.text,
                  pcPath: pcPath,
                );
                Navigator.pop(context, folder);
              }
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _folders.add(result);
      });
    }
  }

  void _removeFolder(int index) {
    setState(() {
      _folders.removeAt(index);
    });
  }

  void _saveConfiguration() {
    if (!_formKey.currentState!.validate()) return;

    if (_folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aggiungi almeno una cartella da backuppare'),
        ),
      );
      return;
    }

    final config = BackupConfig(
      id:
          widget.existingConfig?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      deviceId: widget.device.id,
      name: _nameController.text,
      folders: _folders,
      syncMode: _syncMode,
      deleteMode: _deleteMode,
      autoBackup: _autoBackup,
      scheduleIntervalMinutes: _scheduleInterval,
    );

    context.read<AppState>().saveConfig(config);
    Navigator.pop(context);
  }
}

class _DeviceInfo extends StatelessWidget {
  final MobileDevice device;

  const _DeviceInfo({required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              device.type == DeviceType.android
                  ? Icons.android
                  : Icons.phone_iphone,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${device.model} • ${device.osVersion}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoldersSection extends StatelessWidget {
  final List<BackupFolder> folders;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _FoldersSection({
    required this.folders,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Cartelle da Backuppare',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (folders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Nessuna cartella configurata',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          ...folders.asMap().entries.map((entry) {
            final index = entry.key;
            final folder = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.folder),
                title: Text(folder.phonePath),
                subtitle: Text(folder.pcPath),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onRemove(index),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _SyncModeSection extends StatelessWidget {
  final SyncMode syncMode;
  final void Function(SyncMode) onChanged;

  const _SyncModeSection({required this.syncMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modalità di Sincronizzazione',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _OptionCard(
          title: 'Telefono → PC',
          subtitle: 'Copia i file solo dal telefono al PC',
          icon: Icons.phone_android,
          isSelected: syncMode == SyncMode.phoneToPC,
          onTap: () => onChanged(SyncMode.phoneToPC),
        ),
        _OptionCard(
          title: 'PC → Telefono',
          subtitle: 'Copia i file solo dal PC al telefono',
          icon: Icons.computer,
          isSelected: syncMode == SyncMode.pcToPhone,
          onTap: () => onChanged(SyncMode.pcToPhone),
        ),
        _OptionCard(
          title: 'Bidirezionale',
          subtitle: 'Sincronizza in entrambe le direzioni',
          icon: Icons.sync_alt,
          isSelected: syncMode == SyncMode.bidirectional,
          onTap: () => onChanged(SyncMode.bidirectional),
        ),
      ],
    );
  }
}

class _DeleteModeSection extends StatelessWidget {
  final DeleteMode deleteMode;
  final void Function(DeleteMode) onChanged;

  const _DeleteModeSection({required this.deleteMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestione Cancellazione',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _OptionCard(
          title: 'Non eliminare',
          subtitle: 'Mantieni i file su entrambi i dispositivi',
          icon: Icons.save,
          isSelected: deleteMode == DeleteMode.none,
          onTap: () => onChanged(DeleteMode.none),
        ),
        _OptionCard(
          title: 'Elimina su telefono',
          subtitle: 'Rimuovi i file dal telefono dopo il backup',
          icon: Icons.phone_android,
          isSelected: deleteMode == DeleteMode.deleteOnPhone,
          onTap: () => onChanged(DeleteMode.deleteOnPhone),
        ),
        _OptionCard(
          title: 'Elimina su PC',
          subtitle: 'Rimuovi i file dal PC',
          icon: Icons.computer,
          isSelected: deleteMode == DeleteMode.deleteOnPC,
          onTap: () => onChanged(DeleteMode.deleteOnPC),
        ),
        _OptionCard(
          title: 'Elimina su entrambi',
          subtitle: 'Rimuovi i file da telefono e PC',
          icon: Icons.delete_forever,
          isSelected: deleteMode == DeleteMode.deleteOnBoth,
          onTap: () => onChanged(DeleteMode.deleteOnBoth),
        ),
      ],
    );
  }
}

class _AutoBackupSection extends StatelessWidget {
  final bool autoBackup;
  final int? scheduleInterval;
  final void Function(bool) onAutoBackupChanged;
  final void Function(int?) onIntervalChanged;

  const _AutoBackupSection({
    required this.autoBackup,
    required this.scheduleInterval,
    required this.onAutoBackupChanged,
    required this.onIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Backup Automatico'),
          subtitle: const Text('Esegui backup automaticamente'),
          value: autoBackup,
          onChanged: onAutoBackupChanged,
        ),
        if (autoBackup) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Intervallo di backup',
              border: OutlineInputBorder(),
            ),
            initialValue: scheduleInterval,
            items: const [
              DropdownMenuItem(value: 30, child: Text('Ogni 30 minuti')),
              DropdownMenuItem(value: 60, child: Text('Ogni ora')),
              DropdownMenuItem(value: 360, child: Text('Ogni 6 ore')),
              DropdownMenuItem(value: 720, child: Text('Ogni 12 ore')),
              DropdownMenuItem(value: 1440, child: Text('Ogni giorno')),
            ],
            onChanged: onIntervalChanged,
          ),
        ],
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer.withOpacity(0.7)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
