import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/device.dart';
import '../models/backup_config.dart';
import '../providers/app_state.dart';
import '../widgets/phone_folder_browser.dart';

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
              onAddFullBackup: _addFullBackupPreset,
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
    final appState = context.read<AppState>();

    // Prima seleziona la cartella del telefono usando il browser
    String? phonePath;

    await showDialog(
      context: context,
      builder: (context) => PhoneFolderBrowser(
        device: widget.device,
        deviceManager: appState.deviceManager,
        initialPath: widget.device.type == DeviceType.android ? '/sdcard' : '/',
        onFolderSelected: (path) {
          phonePath = path;
        },
      ),
    );

    if (phonePath == null || !mounted) return;

    // Poi seleziona la cartella del PC
    final pcPath = await FilePicker.platform.getDirectoryPath();
    if (pcPath == null) return;

    if (!mounted) return;

    // Mostra dialog per opzioni aggiuntive
    final result = await showDialog<BackupFolder>(
      context: context,
      builder: (context) =>
          _AddFolderDialog(phonePath: phonePath!, pcPath: pcPath),
    );

    if (result != null) {
      setState(() {
        _folders.add(result);
      });
    }
  }

  Future<void> _addFullBackupPreset() async {
    // Seleziona la cartella base del PC per il backup
    final pcBasePath = await FilePicker.platform.getDirectoryPath();
    if (pcBasePath == null) return;

    final List<BackupFolder> presetFolders;

    if (widget.device.type == DeviceType.android) {
      // Preset per Android: cartelle comuni
      presetFolders = [
        BackupFolder(
          id: '${DateTime.now().millisecondsSinceEpoch}_dcim',
          phonePath: '/sdcard/DCIM',
          pcPath: '$pcBasePath/DCIM',
          includeSubfolders: true,
        ),
        BackupFolder(
          id: '${DateTime.now().millisecondsSinceEpoch}_pictures',
          phonePath: '/sdcard/Pictures',
          pcPath: '$pcBasePath/Pictures',
          includeSubfolders: true,
        ),
        BackupFolder(
          id: '${DateTime.now().millisecondsSinceEpoch}_download',
          phonePath: '/sdcard/Download',
          pcPath: '$pcBasePath/Download',
          includeSubfolders: true,
        ),
        BackupFolder(
          id: '${DateTime.now().millisecondsSinceEpoch}_documents',
          phonePath: '/sdcard/Documents',
          pcPath: '$pcBasePath/Documents',
          includeSubfolders: true,
        ),
        BackupFolder(
          id: '${DateTime.now().millisecondsSinceEpoch}_music',
          phonePath: '/sdcard/Music',
          pcPath: '$pcBasePath/Music',
          includeSubfolders: true,
        ),
        BackupFolder(
          id: '${DateTime.now().millisecondsSinceEpoch}_videos',
          phonePath: '/sdcard/Movies',
          pcPath: '$pcBasePath/Movies',
          includeSubfolders: true,
        ),
      ];
    } else {
      // Per iOS, il backup completo è gestito diversamente
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Per iOS, usa il backup iCloud o iTunes per un backup completo',
          ),
        ),
      );
      return;
    }

    setState(() {
      _folders.addAll(presetFolders);
      _nameController.text = 'Backup Completo ${widget.device.name}';
    });

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Aggiunte ${presetFolders.length} cartelle per il backup completo',
        ),
      ),
    );
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
  final VoidCallback onAddFullBackup;
  final void Function(int) onRemove;

  const _FoldersSection({
    required this.folders,
    required this.onAdd,
    required this.onAddFullBackup,
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
              onPressed: onAddFullBackup,
              icon: const Icon(Icons.backup),
              label: const Text('Backup Completo'),
            ),
            const SizedBox(width: 8),
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
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.7)
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

class _AddFolderDialog extends StatefulWidget {
  final String phonePath;
  final String pcPath;

  const _AddFolderDialog({required this.phonePath, required this.pcPath});

  @override
  State<_AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<_AddFolderDialog> {
  bool _includeSubfolders = true;
  final List<String> _excludeExtensions = [];
  final List<String> _excludeFolders = [];
  final _extensionController = TextEditingController();

  @override
  void dispose() {
    _extensionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configura Cartella'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mostra i percorsi selezionati
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_android, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.phonePath,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.computer, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.pcPath,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Opzioni
              SwitchListTile(
                title: const Text('Includi sottocartelle'),
                subtitle: const Text(
                  'Backup ricorsivo di tutte le sottocartelle',
                ),
                value: _includeSubfolders,
                onChanged: (value) =>
                    setState(() => _includeSubfolders = value),
              ),
              const SizedBox(height: 16),

              // Escludi estensioni
              Text(
                'Escludi estensioni',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _extensionController,
                      decoration: const InputDecoration(
                        hintText: 'es: .tmp, .log',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_extensionController.text.isNotEmpty) {
                        setState(() {
                          _excludeExtensions.add(_extensionController.text);
                          _extensionController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              if (_excludeExtensions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _excludeExtensions.map((ext) {
                    return Chip(
                      label: Text(ext),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() => _excludeExtensions.remove(ext));
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            final folder = BackupFolder(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              phonePath: widget.phonePath,
              pcPath: widget.pcPath,
              includeSubfolders: _includeSubfolders,
              excludeExtensions: _excludeExtensions,
              excludeFolders: _excludeFolders,
            );
            Navigator.pop(context, folder);
          },
          child: const Text('Aggiungi'),
        ),
      ],
    );
  }
}
