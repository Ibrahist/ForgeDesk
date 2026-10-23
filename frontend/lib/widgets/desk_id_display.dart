import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import 'glass_card.dart';
import 'glowing_badge.dart';

class DeskIdDisplayCard extends StatefulWidget {
  final String peerId;
  final String tempPassword;
  final bool isHosting;
  final bool isConnectedToServer;
  final String serverUrl;
  final bool isSelfHosted;
  final VoidCallback onRegeneratePassword;
  final ValueChanged<bool> onToggleHosting;

  const DeskIdDisplayCard({
    super.key,
    required this.peerId,
    required this.tempPassword,
    required this.isHosting,
    required this.isConnectedToServer,
    required this.serverUrl,
    required this.isSelfHosted,
    required this.onRegeneratePassword,
    required this.onToggleHosting,
  });

  @override
  State<DeskIdDisplayCard> createState() => _DeskIdDisplayCardState();
}

class _DeskIdDisplayCardState extends State<DeskIdDisplayCard> {
  bool _showPassword = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: ForgeColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('$label copied to clipboard'),
          ],
        ),
        backgroundColor: ForgeColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Section title and Hosting Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ForgeColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.desktop_windows_outlined,
                        color: ForgeColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This Device',
                            style: TextStyle(
                              color: ForgeColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Allow remote control of this computer',
                            style: TextStyle(
                              color: ForgeColors.textMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GlowingBadge(
                label: widget.isHosting ? 'READY' : 'PAUSED',
                color: widget.isHosting ? ForgeColors.success : ForgeColors.offline,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 9-Digit Peer ID Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: ForgeColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ForgeColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR ID',
                      style: TextStyle(
                        color: ForgeColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.peerId,
                      style: const TextStyle(
                        color: ForgeColors.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.0,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(widget.peerId, 'Device ID'),
                  icon: const Icon(Icons.copy_rounded, color: ForgeColors.textSecondary, size: 20),
                  tooltip: 'Copy ID',
                  style: IconButton.styleFrom(
                    backgroundColor: ForgeColors.surface,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // One-Time Password Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: ForgeColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ForgeColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ONE-TIME PASSWORD',
                      style: TextStyle(
                        color: ForgeColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _showPassword ? widget.tempPassword : '••••••',
                      style: const TextStyle(
                        color: ForgeColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4.0,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                      icon: Icon(
                        _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: ForgeColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: _showPassword ? 'Hide password' : 'Show password',
                      style: IconButton.styleFrom(
                        backgroundColor: ForgeColors.surface,
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: widget.onRegeneratePassword,
                      icon: const Icon(Icons.refresh_rounded, color: ForgeColors.textSecondary, size: 20),
                      tooltip: 'Generate new password',
                      style: IconButton.styleFrom(
                        backgroundColor: ForgeColors.surface,
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _copyToClipboard(widget.tempPassword, 'Password'),
                      icon: const Icon(Icons.copy_rounded, color: ForgeColors.textSecondary, size: 20),
                      tooltip: 'Copy Password',
                      style: IconButton.styleFrom(
                        backgroundColor: ForgeColors.surface,
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Server info & Service Toggle footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isConnectedToServer ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                    size: 16,
                    color: widget.isConnectedToServer ? ForgeColors.success : ForgeColors.offline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isSelfHosted
                        ? 'Self-Hosted (${widget.serverUrl})'
                        : 'ForgeDesk Network (${widget.serverUrl})',
                    style: const TextStyle(
                      color: ForgeColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Host Service:',
                    style: TextStyle(
                      color: ForgeColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: widget.isHosting,
                    activeColor: ForgeColors.primary,
                    activeTrackColor: ForgeColors.primary.withOpacity(0.3),
                    inactiveThumbColor: ForgeColors.textMuted,
                    inactiveTrackColor: ForgeColors.surfaceLight,
                    onChanged: widget.onToggleHosting,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
