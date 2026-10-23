class ClientSettings {
  final String rendezvousServer;
  final String relayServer;
  final String serverKey;
  final bool isSelfHosted;
  final String alias;
  final String defaultQuality;
  final bool allowRemoteInput;
  final bool syncClipboard;

  ClientSettings({
    required this.rendezvousServer,
    required this.relayServer,
    required this.serverKey,
    required this.isSelfHosted,
    required this.alias,
    required this.defaultQuality,
    required this.allowRemoteInput,
    required this.syncClipboard,
  });

  factory ClientSettings.defaultSettings() {
    return ClientSettings(
      rendezvousServer: '127.0.0.1:21115',
      relayServer: '127.0.0.1:21117',
      serverKey: '',
      isSelfHosted: false,
      alias: 'My Workstation',
      defaultQuality: 'balanced',
      allowRemoteInput: true,
      syncClipboard: true,
    );
  }

  factory ClientSettings.fromJson(Map<String, dynamic> json) {
    return ClientSettings(
      rendezvousServer: json['rendezvous_server'] as String? ?? '127.0.0.1:21115',
      relayServer: json['relay_server'] as String? ?? '127.0.0.1:21117',
      serverKey: json['server_key'] as String? ?? '',
      isSelfHosted: json['is_self_hosted'] as bool? ?? false,
      alias: json['alias'] as String? ?? 'My Workstation',
      defaultQuality: json['default_quality'] as String? ?? 'balanced',
      allowRemoteInput: json['allow_remote_input'] as bool? ?? true,
      syncClipboard: json['sync_clipboard'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rendezvous_server': rendezvousServer,
      'relay_server': relayServer,
      'server_key': serverKey,
      'is_self_hosted': isSelfHosted,
      'alias': alias,
      'default_quality': defaultQuality,
      'allow_remote_input': allowRemoteInput,
      'sync_clipboard': syncClipboard,
    };
  }

  ClientSettings copyWith({
    String? rendezvousServer,
    String? relayServer,
    String? serverKey,
    bool? isSelfHosted,
    String? alias,
    String? defaultQuality,
    bool? allowRemoteInput,
    bool? syncClipboard,
  }) {
    return ClientSettings(
      rendezvousServer: rendezvousServer ?? this.rendezvousServer,
      relayServer: relayServer ?? this.relayServer,
      serverKey: serverKey ?? this.serverKey,
      isSelfHosted: isSelfHosted ?? this.isSelfHosted,
      alias: alias ?? this.alias,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      allowRemoteInput: allowRemoteInput ?? this.allowRemoteInput,
      syncClipboard: syncClipboard ?? this.syncClipboard,
    );
  }
}
