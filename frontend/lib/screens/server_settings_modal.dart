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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? ForgeColors.surface : Colors.white;
    final dialogBorder = isDark ? ForgeColors.border : const Color(0xFFCBD5E1);
    final titleColor = isDark ? ForgeColors.textPrimary : ForgeLightColors.textPrimary;
    final mutedColor = isDark ? ForgeColors.textMuted : ForgeLightColors.textMuted;
    final selectorBg = isDark ? ForgeColors.surfaceLight : const Color(0xFFF1F5F9);
    final selectorBorder = isDark ? ForgeColors.border : const Color(0xFFE2E8F0);
    final tabActiveBg = isDark ? ForgeColors.card : Colors.white;
    final inputBg = isDark ? ForgeColors.surfaceLight : const Color(0xFFF8FAFC);

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: dialogBorder),
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
                    Row(
                      children: [
                        const Icon(Icons.dns_rounded, color: ForgeColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Server & Privacy Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: mutedColor),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Server Mode Selector (Public vs Self-Hosted)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: selectorBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selectorBorder),
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
                              color: !_isSelfHosted ? tabActiveBg : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !isDark && !_isSelfHosted
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF1E293B).withValues(alpha: 0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Public Network (Default)',
                              style: TextStyle(
                                color: !_isSelfHosted ? ForgeColors.primary : mutedColor,
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
                              color: _isSelfHosted ? tabActiveBg : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !isDark && _isSelfHosted
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF1E293B).withValues(alpha: 0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Private Self-Hosted Server',
                              style: TextStyle(
                                color: _isSelfHosted ? ForgeColors.primary : mutedColor,
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
                    backgroundColor: isDark
                        ? ForgeColors.surfaceLight.withValues(alpha: 0.5)
                        : const Color(0xFFF8FAFC),
                    borderColor: isDark ? ForgeColors.border : const Color(0xFFBFDBFE),
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
                          style: TextStyle(color: titleColor),
                          decoration: InputDecoration(
                            labelText: 'Rendezvous / Signaling Server Host',
                            labelStyle: TextStyle(
                              color: isDark ? ForgeColors.secondary : ForgeLightColors.primary,
                            ),
                            hintText: 'e.g. 192.168.1.100:21115 or relay.domain.com:21115',
                            hintStyle: TextStyle(color: mutedColor),
                            fillColor: inputBg,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _relayCtrl,
                          style: TextStyle(color: titleColor),
                          decoration: InputDecoration(
                            labelText: 'Relay Server Host',
                            labelStyle: TextStyle(
                              color: isDark ? ForgeColors.secondary : ForgeLightColors.primary,
                            ),
                            hintText: 'e.g. 192.168.1.100:21117 or relay.domain.com:21117',
                            hintStyle: TextStyle(color: mutedColor),
                            fillColor: inputBg,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _keyCtrl,
                          obscureText: true,
                          style: TextStyle(color: titleColor),
                          decoration: InputDecoration(
                            labelText: 'Server Key / Token (Optional)',
                            labelStyle: TextStyle(
                              color: isDark ? ForgeColors.secondary : ForgeLightColors.primary,
                            ),
                            hintText: 'Enter secret server key if required by your server',
                            hintStyle: TextStyle(color: mutedColor),
                            fillColor: inputBg,
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
                  style: TextStyle(color: titleColor),
                  decoration: InputDecoration(
                    labelText: 'Device Alias (Friendly Name)',
                    labelStyle: TextStyle(
                      color: isDark ? ForgeColors.secondary : ForgeLightColors.primary,
                    ),
                    hintText: 'e.g. My Laptop, Studio Mac',
                    hintStyle: TextStyle(color: mutedColor),
                    fillColor: inputBg,
                  ),
                ),

                const SizedBox(height: 20),

                // Privacy and Security Toggles
                SwitchListTile.adaptive(
                  value: _allowRemoteInput,
                  activeThumbColor: ForgeColors.primaryLight,
                  activeTrackColor: ForgeColors.primary.withValues(alpha: 0.4),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Allow Remote Input',
                    style: TextStyle(fontSize: 14, color: titleColor, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Permit connected operators to move mouse and type keyboard',
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                  onChanged: (val) => setState(() => _allowRemoteInput = val),
                ),

                SwitchListTile.adaptive(
                  value: _syncClipboard,
                  activeThumbColor: ForgeColors.primaryLight,
                  activeTrackColor: ForgeColors.primary.withValues(alpha: 0.4),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Clipboard Synchronization',
                    style: TextStyle(fontSize: 14, color: titleColor, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Automatically sync copied text between host and remote',
                    style: TextStyle(fontSize: 12, color: mutedColor),
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? ForgeColors.textPrimary : const Color(0xFF334155),
                        backgroundColor: isDark ? Colors.transparent : const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: isDark ? ForgeColors.border : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveAndClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ForgeColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: ForgeColors.primaryGlow,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Save Configuration',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
