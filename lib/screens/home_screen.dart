import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../providers/app_state.dart';
import '../widgets/device_card.dart';
import '../widgets/backup_config_list.dart';
import '../widgets/proximity_backup_panel.dart';
import '../widgets/wireless_setup_dialog.dart';
import 'backup_config_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('i13Pro Backup Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Devices',
            onPressed: () {
              context.read<AppState>().deviceManager.refreshDevices();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Pannello Proximity Backup
          const ProximityBackupPanel(),
          const Divider(height: 1),

          // Area principale
          Expanded(
            child: Row(
              children: [
                // Pannello laterale dei dispositivi
                SizedBox(width: 350, child: _DevicePanel()),
                const VerticalDivider(width: 1),
                // Area principale delle configurazioni
                Expanded(child: _ConfigPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DevicePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final devices = appState.devices;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.devices,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dispositivi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: devices.isEmpty
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${devices.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: devices.isEmpty
                            ? Colors.white
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_android_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nessun dispositivo connesso',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Collega un dispositivo via USB',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final isSelected =
                            appState.selectedDevice?.id == device.id;

                        return DeviceCard(
                          device: device,
                          isSelected: isSelected,
                          onTap: () => appState.selectDevice(device),
                          onSetupWireless: device.type == DeviceType.android
                              ? () => _showWirelessSetup(context, device)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ConfigPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final selectedDevice = appState.selectedDevice;

        if (selectedDevice == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Seleziona un dispositivo',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scegli un dispositivo dalla lista per gestire i backup',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final configs = appState.getConfigsForSelectedDevice();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.backup,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Configurazioni Backup',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BackupConfigScreen(device: selectedDevice),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nuova Configurazione'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BackupConfigList(configs: configs, device: selectedDevice),
            ),
          ],
        );
      },
    );
  }
}

void _showWirelessSetup(BuildContext context, MobileDevice device) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => WirelessSetupDialog(device: device),
  );

  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✅ Connessione wireless configurata! '
          'Ora puoi scollegare il cavo USB.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }
}
