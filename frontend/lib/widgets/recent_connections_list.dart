import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/remote_session.dart';
import 'glass_card.dart';

class RecentConnectionsList extends StatelessWidget {
  final List<RecentSessionItem> sessions;
  final ValueChanged<RecentSessionItem> onSelectSession;
  final ValueChanged<RecentSessionItem> onRemoveSession;

  const RecentConnectionsList({
    super.key,
    required this.sessions,
    required this.onSelectSession,
    required this.onRemoveSession,
  });

  IconData _getOsIcon(String osType) {
    switch (osType.toLowerCase()) {
      case 'linux':
        return Icons.terminal_rounded;
      case 'macos':
      case 'ios':
        return Icons.apple_rounded;
      case 'android':
        return Icons.android_rounded;
      default:
        return Icons.window_rounded;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: ForgeColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'Recent Connections',
                style: TextStyle(
                  color: ForgeColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = sessions[index];
            return GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 12,
              onTap: () => onSelectSession(item),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? ForgeColors.surfaceLight
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getOsIcon(item.osType),
                      size: 18,
                      color: ForgeColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.alias,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? ForgeColors.textPrimary
                                : ForgeLightColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              item.id,
                              style: const TextStyle(
                                color: ForgeColors.textMuted,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: ForgeColors.textMuted)),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimeAgo(item.lastConnected),
                              style: const TextStyle(
                                color: ForgeColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => onSelectSession(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ForgeColors.surfaceLight,
                      foregroundColor: ForgeColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      elevation: 0,
                      side: const BorderSide(color: ForgeColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 16),
                        SizedBox(width: 4),
                        Text('Connect', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
