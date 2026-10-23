import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/client_settings.dart';
import '../models/host_status.dart';
import '../models/remote_session.dart';
import '../services/forgedesk_bridge.dart';
import '../services/session_storage.dart';
import '../widgets/desk_id_display.dart';
import '../widgets/glass_card.dart';
import '../widgets/glowing_badge.dart';
import '../widgets/recent_connections_list.dart';
import 'remote_viewer_screen.dart';
import 'server_settings_modal.dart';

class HomeScreen extends StatefulWidget {
  final ForgeDeskBridgeService bridge;
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.bridge,
    this.onToggleTheme,
    this.isDarkMode = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _targetIdCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  String _selectedQuality = 'balanced';
  bool _obscurePassword = true;
  List<RecentSessionItem> _recentSessions = [];
  ClientSettings _clientSettings = ClientSettings.defaultSettings();

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final recents = await SessionStorageService.loadRecentSessions();
    final settings = await SessionStorageService.loadSettings();
    setState(() {
      _recentSessions = recents;
      _clientSettings = settings;
    });
  }

  @override
  void dispose() {
    _targetIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _initiateConnection({String? targetId, String? password}) {
    final id = (targetId ?? _targetIdCtrl.text).trim();
    final pass = (password ?? _passwordCtrl.text).trim();

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a Remote Desk ID'),
          backgroundColor: ForgeColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Save into recents
    final newItem = RecentSessionItem(
      id: id,
      alias: 'Remote Desk ($id)',
      lastConnected: DateTime.now(),
      osType: 'Windows',
    );
    SessionStorageService.addRecentSession(newItem).then((_) {
      _loadStoredData();
    });

    // Send connect command
    widget.bridge.connectRemote(id, pass, quality: _selectedQuality);

    // Navigate to viewer
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RemoteViewerScreen(bridge: widget.bridge),
      ),
    );
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (_) => ServerSettingsModal(
        initialSettings: _clientSettings,
        onSave: (updated) {
          setState(() {
            _clientSettings = updated;
          });
          widget.bridge.updateSettings(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.bridge,
      builder: (context, _) {
        final status = widget.bridge.status;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(status),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 860;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column: This Device Desk Card
                              Expanded(
                                flex: 5,
                                child: DeskIdDisplayCard(
                                  peerId: status.myId,
                                  tempPassword: status.temporaryPassword,
                                  isHosting: status.isHosting,
                                  isConnectedToServer: status.serverConnected,
                                  serverUrl: status.serverUrl,
                                  isSelfHosted: status.isSelfHosted,
                                  onRegeneratePassword: widget.bridge.regeneratePassword,
                                  onToggleHosting: (_) => widget.bridge.toggleHosting(),
                                ),
                              ),
                              const SizedBox(width: 24),

                              // Right Column: Connect Remote Desk + Recents
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    _buildRemoteDeskCard(),
                                    const SizedBox(height: 20),
                                    RecentConnectionsList(
                                      sessions: _recentSessions,
                                      isDarkMode: widget.isDarkMode,
                                      onSelectSession: (item) {
                                        _targetIdCtrl.text = item.id;
                                        _initiateConnection(targetId: item.id);
                                      },
                                      onRemoveSession: (item) {},
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              DeskIdDisplayCard(
                                peerId: status.myId,
                                tempPassword: status.temporaryPassword,
                                isHosting: status.isHosting,
                                isConnectedToServer: status.serverConnected,
                                serverUrl: status.serverUrl,
                                isSelfHosted: status.isSelfHosted,
                                onRegeneratePassword: widget.bridge.regeneratePassword,
                                onToggleHosting: (_) => widget.bridge.toggleHosting(),
                              ),
                              const SizedBox(height: 24),
                              _buildRemoteDeskCard(),
                              const SizedBox(height: 20),
                              RecentConnectionsList(
                                sessions: _recentSessions,
                                isDarkMode: widget.isDarkMode,
                                onSelectSession: (item) {
                                  _targetIdCtrl.text = item.id;
                                  _initiateConnection(targetId: item.id);
                                },
                                onRemoveSession: (item) {},
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
          bottomNavigationBar: _buildFooter(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(HostStatus status) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/branding/ForgeDesk.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ForgeColors.primary, ForgeColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            AppConstants.appName,
            style: TextStyle(
              color: widget.isDarkMode ? ForgeColors.textPrimary : ForgeLightColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        GlowingBadge(
          label: status.isSelfHosted ? 'SELF-HOSTED' : 'FORGEDESK NET',
          color: status.serverConnected ? ForgeColors.primaryLight : ForgeColors.offline,
          icon: status.isSelfHosted ? Icons.dns_rounded : Icons.cloud_done_rounded,
          isPulsing: status.serverConnected,
          tooltip: status.serverConnected
              ? (status.isSelfHosted
                  ? 'Connected to Self-Hosted Relay (${status.serverUrl})'
                  : 'ForgeDesk Cloud Network: Online')
              : 'ForgeDesk Cloud Network: Disconnected',
        ),
        const SizedBox(width: 8),
        if (widget.onToggleTheme != null)
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: widget.isDarkMode ? ForgeColors.textSecondary : ForgeLightColors.textPrimary,
            ),
            tooltip: widget.isDarkMode ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            style: IconButton.styleFrom(
              backgroundColor: widget.isDarkMode ? ForgeColors.surfaceLight : const Color(0xFFEFF6FF),
              side: widget.isDarkMode ? null : const BorderSide(color: Color(0xFFBFDBFE)),
              padding: const EdgeInsets.all(10),
            ),
          ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _openSettings,
          icon: Icon(
            Icons.settings_outlined,
            color: widget.isDarkMode ? ForgeColors.textSecondary : ForgeLightColors.textPrimary,
          ),
          tooltip: 'Server & Network Settings',
          style: IconButton.styleFrom(
            backgroundColor: widget.isDarkMode ? ForgeColors.surfaceLight : const Color(0xFFEFF6FF),
            side: widget.isDarkMode ? null : const BorderSide(color: Color(0xFFBFDBFE)),
            padding: const EdgeInsets.all(10),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildRemoteDeskCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ForgeColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.connected_tv_rounded,
                  color: ForgeColors.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control Remote Desk',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? ForgeColors.textPrimary
                          : ForgeLightColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Access another machine using ID and Password',
                    style: TextStyle(
                      color: ForgeColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Remote ID Input
          TextField(
            controller: _targetIdCtrl,
            style: TextStyle(
              color: isDark ? ForgeColors.textPrimary : ForgeLightColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              labelText: 'Partner ID',
              hintText: 'e.g. 812 491 033 or demo',
              prefixIcon: const Icon(Icons.pin_rounded, color: ForgeColors.textMuted, size: 20),
              suffixIcon: IconButton(
                onPressed: () => _targetIdCtrl.clear(),
                icon: const Icon(Icons.clear_rounded, size: 18, color: ForgeColors.textMuted),
              ),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _initiateConnection(),
          ),

          const SizedBox(height: 14),

          // Password Input
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            style: TextStyle(
              color: isDark ? ForgeColors.textPrimary : ForgeLightColors.textPrimary,
              letterSpacing: 2.0,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter partner access password',
              prefixIcon: const Icon(Icons.key_rounded, color: ForgeColors.textMuted, size: 20),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: ForgeColors.textMuted,
                ),
              ),
            ),
            onSubmitted: (_) => _initiateConnection(),
          ),

          const SizedBox(height: 16),

          // Quality Preset selector
          Row(
            children: [
              const Text('Preset:', style: TextStyle(color: ForgeColors.textMuted, fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? ForgeColors.surfaceLight : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? ForgeColors.border : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedQuality,
                      dropdownColor: isDark ? ForgeColors.surfaceLight : Colors.white,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDark ? ForgeColors.textSecondary : ForgeLightColors.textSecondary,
                      ),
                      style: TextStyle(
                        color: isDark ? ForgeColors.textPrimary : ForgeLightColors.textPrimary,
                        fontSize: 13,
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedQuality = val);
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'balanced',
                          child: Text(
                            'Balanced (1080p, 30 FPS - Recommended)',
                            style: TextStyle(
                              color: isDark ? ForgeColors.textPrimary : ForgeLightColors.textPrimary,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'low',
                          child: Text(
                            'Low Latency (Fast 720p, 60 FPS)',
                            style: TextStyle(
                              color: isDark ? ForgeColors.textPrimary : ForgeLightColors.textPrimary,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Text(
                            'Ultra Quality (1080p, 60 FPS)',
                            style: TextStyle(
                              color: isDark ? ForgeColors.textPrimary : ForgeLightColors.textPrimary,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'view_only',
                          child: Text(
                            'View Only (No input control)',
                            style: TextStyle(
                              color: isDark ? ForgeColors.textPrimary : ForgeLightColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Large glowing Connect Button (Blue & White)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _initiateConnection(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ForgeColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: ForgeColors.primary.withValues(alpha: 0.45),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Connect to Remote Desk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isDark = widget.isDarkMode;
    final footerTextColor = isDark ? ForgeColors.textMuted : ForgeLightColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? ForgeColors.surface : ForgeLightColors.surface,
        border: Border(top: BorderSide(color: isDark ? ForgeColors.border : ForgeLightColors.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security_rounded, size: 14, color: ForgeColors.success),
              const SizedBox(width: 6),
              Text(
                'End-to-End Encrypted Peer-to-Peer Protocol',
                style: TextStyle(
                  color: footerTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            'ForgeDesk v0.1.0 • 100% Self-Hosted & Open Source',
            style: TextStyle(
              color: footerTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
