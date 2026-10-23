import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/client_settings.dart';
import '../services/session_storage.dart';
import '../widgets/glass_card.dart';

class ServerSettingsModal extends StatefulWidget {
  final ClientSettings initialSettings;
  final ValueChanged<ClientSettings> onSave;

  const ServerSettingsModal({
    super.key,
    required this.initialSettings,
    required this.onSave,
  });

  @override
  State<ServerSettingsModal> createState() => _ServerSettingsModalState();
}

class _ServerSettingsModalState extends State<ServerSettingsModal> {
  late bool _isSelfHosted;
  late TextEditingController _rendezvousCtrl;
  late TextEditingController _relayCtrl;
  late TextEditingController _keyCtrl;
  late TextEditingController _aliasCtrl;
  late bool _allowRemoteInput;
  late bool _syncClipboard;

  @override
  void initState() {
    super.initState();
    _isSelfHosted = widget.initialSettings.isSelfHosted;
    _rendezvousCtrl = TextEditingController(text: widget.initialSettings.rendezvousServer);
    _relayCtrl = TextEditingController(text: widget.initialSettings.relayServer);
    _keyCtrl = TextEditingController(text: widget.initialSettings.serverKey);
    _aliasCtrl = TextEditingController(text: widget.initialSettings.alias);
    _allowRemoteInput = widget.initialSettings.allowRemoteInput;
    _syncClipboard = widget.initialSettings.syncClipboard;
  }

  @override
  void dispose() {
    _rendezvousCtrl.dispose();
    _relayCtrl.dispose();
    _keyCtrl.dispose();
    _aliasCtrl.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    final updated = widget.initialSettings.copyWith(
      isSelfHosted: _isSelfHosted,
      rendezvousServer: _rendezvousCtrl.text.trim(),
      relayServer: _relayCtrl.text.trim(),
      serverKey: _keyCtrl.text.trim(),
      alias: _aliasCtrl.text.trim(),
      allowRemoteInput: _allowRemoteInput,
      syncClipboard: _syncClipboard,
    );
    SessionStorageService.saveSettings(updated);
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ForgeColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ForgeColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.dns_rounded, color: ForgeColors.primary, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Server & Privacy Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ForgeColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: ForgeColors.textMuted),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Server Mode Selector (Public vs Self-Hosted)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: ForgeColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ForgeColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSelfHosted = false;
                              _rendezvousCtrl.text = AppConstants.defaultPublicRendezvous;
                              _relayCtrl.text = AppConstants.defaultPublicRelay;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isSelfHosted ? ForgeColors.card : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Public Network (Default)',
                              style: TextStyle(
                                color: !_isSelfHosted ? ForgeColors.primary : ForgeColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSelfHosted = true;
                              if (_rendezvousCtrl.text == AppConstants.defaultPublicRendezvous) {
                                _rendezvousCtrl.text = AppConstants.defaultRendezvousHost;
                                _relayCtrl.text = AppConstants.defaultRelayHost;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isSelfHosted ? ForgeColors.card : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Private Self-Hosted Server',
                              style: TextStyle(
                                color: _isSelfHosted ? ForgeColors.primary : ForgeColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_isSelfHosted) ...[
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: ForgeColors.surfaceLight.withOpacity(0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Self-Hosted Infrastructure',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: ForgeColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _rendezvousCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Rendezvous / Signaling Server Host',
                            hintText: 'e.g. 192.168.1.100:21115 or relay.domain.com:21115',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _relayCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Relay Server Host',
                            hintText: 'e.g. 192.168.1.100:21117 or relay.domain.com:21117',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _keyCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Server Key / Token (Optional)',
                            hintText: 'Enter secret server key if required by your server',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Device Alias
                TextField(
                  controller: _aliasCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Device Alias (Friendly Name)',
                    hintText: 'e.g. My Laptop, Studio Mac',
                  ),
                ),

                const SizedBox(height: 20),

                // Privacy and Security Toggles
                SwitchListTile.adaptive(
                  value: _allowRemoteInput,
                  activeColor: ForgeColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow Remote Input', style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                    'Permit connected operators to move mouse and type keyboard',
                    style: TextStyle(fontSize: 12, color: ForgeColors.textMuted),
                  ),
                  onChanged: (val) => setState(() => _allowRemoteInput = val),
                ),

                SwitchListTile.adaptive(
                  value: _syncClipboard,
                  activeColor: ForgeColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Clipboard Synchronization', style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                    'Automatically sync copied text between host and remote',
                    style: TextStyle(fontSize: 12, color: ForgeColors.textMuted),
                  ),
                  onChanged: (val) => setState(() => _syncClipboard = val),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveAndClose,
                      child: const Text('Save Configuration'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
