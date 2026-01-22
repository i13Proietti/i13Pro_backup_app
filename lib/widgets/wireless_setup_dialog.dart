import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../providers/app_state.dart';

class WirelessSetupDialog extends StatefulWidget {
  final MobileDevice device;

  const WirelessSetupDialog({super.key, required this.device});

  @override
  State<WirelessSetupDialog> createState() => _WirelessSetupDialogState();
}

class _WirelessSetupDialogState extends State<WirelessSetupDialog> {
  bool _isSettingUp = false;
  String? _deviceIP;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wifi, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Setup Connessione Wireless',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Info dispositivo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.device.type == DeviceType.android
                        ? Icons.android
                        : Icons.phone_iphone,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.device.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          widget.device.model,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_deviceIP == null) ...[
              // Istruzioni setup
              _buildInstructions(),
              const SizedBox(height: 24),

              // Pulsante setup
              if (_isSettingUp)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _setupWireless,
                    icon: const Icon(Icons.settings_remote),
                    label: const Text('Abilita Connessione Wireless'),
                  ),
                ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Setup completato
              _buildSuccessView(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Come funziona:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildStep(
          '1',
          'Assicurati che telefono e PC siano sulla stessa rete WiFi',
          Icons.wifi,
        ),
        _buildStep(
          '2',
          'Mantieni il telefono collegato via USB durante il setup',
          Icons.usb,
        ),
        _buildStep(
          '3',
          'Click su "Abilita Connessione Wireless"',
          Icons.touch_app,
        ),
        _buildStep(
          '4',
          'Dopo il setup, scollega il cavo USB e riconnetti wireless!',
          Icons.phonelink_off,
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Connessione Wireless Abilitata!',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Indirizzo IP del dispositivo:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _deviceIP!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _deviceIP!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('IP copiato negli appunti'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: 'Copia IP',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          '✅ Ora puoi scollegare il cavo USB!',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Il telefono si connetterà automaticamente quando è sulla stessa rete WiFi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Fatto!'),
          ),
        ),
      ],
    );
  }

  Future<void> _setupWireless() async {
    setState(() {
      _isSettingUp = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      final ip = await appState.setupWirelessConnection(widget.device);

      if (ip != null) {
        setState(() {
          _deviceIP = ip;
          _isSettingUp = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Impossibile ottenere l\'IP del dispositivo. '
              'Assicurati che sia connesso al WiFi.';
          _isSettingUp = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante il setup: $e';
        _isSettingUp = false;
      });
    }
  }
}
