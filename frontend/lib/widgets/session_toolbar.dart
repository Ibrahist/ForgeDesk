import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/remote_session.dart';

class SessionToolbar extends StatelessWidget {
  final RemoteSessionState session;
  final VoidCallback onToggleFullscreen;
  final ValueChanged<RemoteViewScaleMode> onScaleModeChanged;
  final VoidCallback onSendCtrlAltDel;
  final VoidCallback onSendLock;
  final VoidCallback onToggleChat;
  final VoidCallback onDisconnect;

  const SessionToolbar({
    super.key,
    required this.session,
    required this.onToggleFullscreen,
    required this.onScaleModeChanged,
    required this.onSendCtrlAltDel,
    required this.onSendLock,
    required this.onToggleChat,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ForgeColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ForgeColors.border.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Remote Peer ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ForgeColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ForgeColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  session.remotePeerId,
                  style: const TextStyle(
                    color: ForgeColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Telemetry Stats: FPS & Latency
          Text(
            '${session.fps.toStringAsFixed(0)} FPS',
            style: const TextStyle(color: ForgeColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          const Text('•', style: TextStyle(color: ForgeColors.textMuted)),
          const SizedBox(width: 8),
          Text(
            '${session.latencyMs}ms',
            style: const TextStyle(color: ForgeColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(width: 8),
          const Text('•', style: TextStyle(color: ForgeColors.textMuted)),
          const SizedBox(width: 8),
          Text(
            '${session.bitrateKbps} kbps',
            style: const TextStyle(color: ForgeColors.textMuted, fontSize: 11),
          ),

          const SizedBox(width: 14),
          Container(width: 1, height: 20, color: ForgeColors.border),
          const SizedBox(width: 10),

          // Quick Action: Ctrl+Alt+Del
          IconButton(
            onPressed: onSendCtrlAltDel,
            icon: const Icon(Icons.keyboard_command_key_rounded, size: 18),
            tooltip: 'Send Ctrl + Alt + Del',
            color: ForgeColors.textSecondary,
          ),

          // Quick Action: Lock Workstation
          IconButton(
            onPressed: onSendLock,
            icon: const Icon(Icons.lock_outline_rounded, size: 18),
            tooltip: 'Lock Remote Desktop',
            color: ForgeColors.textSecondary,
          ),

          // Scale Mode selector
          PopupMenuButton<RemoteViewScaleMode>(
            initialValue: session.scaleMode,
            tooltip: 'Scale Mode',
            color: ForgeColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: ForgeColors.border),
            ),
            icon: const Icon(Icons.aspect_ratio_rounded, size: 18, color: ForgeColors.textSecondary),
            onSelected: onScaleModeChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: RemoteViewScaleMode.fit,
                child: Text('Fit to Window', style: TextStyle(fontSize: 13)),
              ),
              const PopupMenuItem(
                value: RemoteViewScaleMode.original,
                child: Text('Original 100% (1:1)', style: TextStyle(fontSize: 13)),
              ),
              const PopupMenuItem(
                value: RemoteViewScaleMode.stretch,
                child: Text('Stretch to Fill', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),

          // In-Session Chat
          IconButton(
            onPressed: onToggleChat,
            icon: Icon(
              session.isChatOpen ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
              size: 18,
            ),
            tooltip: 'Remote Chat',
            color: session.isChatOpen ? ForgeColors.primary : ForgeColors.textSecondary,
          ),

          // Fullscreen Toggle
          IconButton(
            onPressed: onToggleFullscreen,
            icon: Icon(
              session.isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
              size: 20,
            ),
            tooltip: session.isFullscreen ? 'Exit Fullscreen' : 'Enter Fullscreen',
            color: ForgeColors.textSecondary,
          ),

          const SizedBox(width: 6),

          // Disconnect Button
          ElevatedButton(
            onPressed: onDisconnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: ForgeColors.error.withOpacity(0.2),
              foregroundColor: ForgeColors.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              side: BorderSide(color: ForgeColors.error.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.power_settings_new_rounded, size: 16),
                SizedBox(width: 4),
                Text('Disconnect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
