import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/device_manager.dart';

class PhoneFolderBrowser extends StatefulWidget {
  final MobileDevice device;
  final DeviceManager deviceManager;
  final String initialPath;
  final Function(String) onFolderSelected;

  const PhoneFolderBrowser({
    super.key,
    required this.device,
    required this.deviceManager,
    this.initialPath = '/',
    required this.onFolderSelected,
  });

  @override
  State<PhoneFolderBrowser> createState() => _PhoneFolderBrowserState();
}

class _PhoneFolderBrowserState extends State<PhoneFolderBrowser> {
  late String _currentPath;
  List<FileItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _loadFolder(_currentPath);
  }

  Future<void> _loadFolder(String path) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final files = await widget.deviceManager.listFiles(widget.device, path);
      final items = <FileItem>[];

      for (var fileName in files) {
        final fullPath = path.endsWith('/')
            ? '$path$fileName'
            : '$path/$fileName';

        try {
          final info = await widget.deviceManager.getFileInfo(
            widget.device,
            fullPath,
          );

          items.add(
            FileItem(
              name: fileName,
              path: fullPath,
              isDirectory: info['isDirectory'] as bool? ?? false,
              size: info['size'] as int? ?? 0,
              modified: info['modified'] as DateTime?,
            ),
          );
        } catch (e) {
          debugPrint('Error getting info for $fileName: $e');
          // Assume che sia una directory se non riusciamo a ottenere info
          items.add(
            FileItem(
              name: fileName,
              path: fullPath,
              isDirectory: true,
              size: 0,
            ),
          );
        }
      }

      // Ordina: prima le directory, poi i file
      items.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.compareTo(b.name);
      });

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateUp() {
    if (_currentPath == '/' || _currentPath.isEmpty) return;

    final parts = _currentPath.split('/');
    parts.removeLast();
    final newPath = parts.isEmpty ? '/' : parts.join('/');

    setState(() {
      _currentPath = newPath;
    });
    _loadFolder(_currentPath);
  }

  void _navigateToFolder(String path) {
    setState(() {
      _currentPath = path;
    });
    _loadFolder(path);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.device.type == DeviceType.android
                      ? Icons.android
                      : Icons.phone_iphone,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Seleziona Cartella',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Breadcrumb path
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: _currentPath == '/' ? null : _navigateUp,
                    tooltip: 'Cartella superiore',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentPath,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // File list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text('Errore: $_errorMessage'),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => _loadFolder(_currentPath),
                            child: const Text('Riprova'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          leading: Icon(
                            item.isDirectory
                                ? Icons.folder
                                : Icons.insert_drive_file,
                            color: item.isDirectory
                                ? Colors.amber[700]
                                : Colors.grey,
                          ),
                          title: Text(item.name),
                          subtitle: item.isDirectory
                              ? null
                              : Text(_formatFileSize(item.size)),
                          trailing: item.isDirectory
                              ? const Icon(Icons.chevron_right)
                              : null,
                          onTap: item.isDirectory
                              ? () => _navigateToFolder(item.path)
                              : null,
                        );
                      },
                    ),
            ),

            const Divider(),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annulla'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    widget.onFolderSelected(_currentPath);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Seleziona Cartella'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime? modified;

  FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    this.modified,
  });
}
