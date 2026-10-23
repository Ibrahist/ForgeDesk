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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? ForgeColors.surfaceLight : const Color(0xFFEFF6FF);
    final containerBorder = isDark ? ForgeColors.border : const Color(0xFFBFDBFE);
    final titleColor = isDark ? ForgeColors.textPrimary : ForgeLightColors.textPrimary;

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
                        color: ForgeColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.desktop_windows_outlined,
                        color: ForgeColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This Device',
                            style: TextStyle(
                              color: titleColor,
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
                color: widget.isHosting ? ForgeColors.success : ForgeColors.warning,
                isPulsing: widget.isHosting,
                tooltip: widget.isHosting
                    ? 'Host Service is Active • Click to Pause'
                    : 'Host Service is Paused • Click to Resume',
                onTap: () => widget.onToggleHosting(!widget.isHosting),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 9-Digit Peer ID Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: containerBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: containerBorder),
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
                  icon: Icon(
                    Icons.copy_rounded,
                    color: isDark ? ForgeColors.textSecondary : ForgeLightColors.textPrimary,
                    size: 20,
                  ),
                  tooltip: 'Copy ID',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? ForgeColors.surface : const Color(0xFFEFF6FF),
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
              color: containerBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: containerBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
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
                        style: TextStyle(
                          color: isDark ? ForgeColors.textPrimary : ForgeLightColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                      icon: Icon(
                        _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: isDark ? ForgeColors.textSecondary : ForgeLightColors.textPrimary,
                        size: 20,
                      ),
                      tooltip: _showPassword ? 'Hide password' : 'Show password',
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? ForgeColors.surface : const Color(0xFFEFF6FF),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: widget.onRegeneratePassword,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: isDark ? ForgeColors.textSecondary : ForgeLightColors.textPrimary,
                        size: 20,
                      ),
                      tooltip: 'Generate new password',
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? ForgeColors.surface : const Color(0xFFEFF6FF),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _copyToClipboard(widget.tempPassword, 'Password'),
                      icon: Icon(
                        Icons.copy_rounded,
                        color: isDark ? ForgeColors.textSecondary : ForgeLightColors.textPrimary,
                        size: 20,
                      ),
                      tooltip: 'Copy Password',
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? ForgeColors.surface : const Color(0xFFEFF6FF),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
                        : 'ForgeDesk Network',
                    style: const TextStyle(
                      color: ForgeColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
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
                    activeThumbColor: ForgeColors.primaryLight,
                    activeTrackColor: ForgeColors.primary.withValues(alpha: 0.4),
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
