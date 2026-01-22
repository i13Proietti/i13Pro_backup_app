import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ProximityBackupPanel extends StatelessWidget {
  const ProximityBackupPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final isEnabled = appState.proximityBackupEnabled;
        final wirelessDevices = appState.wirelessDevices;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEnabled
                ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isEnabled ? Icons.wifi_tethering : Icons.wifi_off,
                    color: isEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backup Automatico Proximity',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isEnabled
                              ? 'In ascolto per dispositivi vicini'
                              : 'Disabilitato',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: (value) {
                      appState.toggleProximityBackup(value);

                      if (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '📡 Proximity Backup attivato! '
                              'I backup si avvieranno automaticamente quando i dispositivi sono vicini.',
                            ),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              if (isEnabled) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(Icons.devices, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Dispositivi rilevati: ${wirelessDevices.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),

                if (wirelessDevices.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...wirelessDevices.map((device) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const SizedBox(width: 28),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              device.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            device.ipAddress,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'I backup si avviano automaticamente quando i dispositivi sono sulla stessa rete WiFi',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
