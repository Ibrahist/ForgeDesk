class HostStatus {
  final String myId;
  final String temporaryPassword;
  final bool hasPermanentPassword;
  final bool isHosting;
  final bool serverConnected;
  final String serverUrl;
  final bool isSelfHosted;
  final int activeClientCount;
  final bool remoteConnected;
  final String? remotePeerId;

  HostStatus({
    required this.myId,
    required this.temporaryPassword,
    required this.hasPermanentPassword,
    required this.isHosting,
    required this.serverConnected,
    required this.serverUrl,
    required this.isSelfHosted,
    required this.activeClientCount,
    required this.remoteConnected,
    this.remotePeerId,
  });

  factory HostStatus.fromJson(Map<String, dynamic> json) {
    return HostStatus(
      myId: json['my_id'] as String? ?? '000 000 000',
      temporaryPassword: json['temporary_password'] as String? ?? '------',
      hasPermanentPassword: json['has_permanent_password'] as bool? ?? false,
      isHosting: json['is_hosting'] as bool? ?? false,
      serverConnected: json['server_connected'] as bool? ?? false,
      serverUrl: json['server_url'] as String? ?? '127.0.0.1:21115',
      isSelfHosted: json['is_self_hosted'] as bool? ?? false,
      activeClientCount: json['active_client_count'] as int? ?? 0,
      remoteConnected: json['remote_connected'] as bool? ?? false,
      remotePeerId: json['remote_peer_id'] as String?,
    );
  }

  factory HostStatus.initial() {
    return HostStatus(
      myId: '496 835 401',
      temporaryPassword: '8k2pX9',
      hasPermanentPassword: false,
      isHosting: true,
      serverConnected: true,
      serverUrl: '127.0.0.1:21115',
      isSelfHosted: false,
      activeClientCount: 0,
      remoteConnected: false,
    );
  }

  HostStatus copyWith({
    String? myId,
    String? temporaryPassword,
    bool? hasPermanentPassword,
    bool? isHosting,
    bool? serverConnected,
    String? serverUrl,
    bool? isSelfHosted,
    int? activeClientCount,
    bool? remoteConnected,
    String? remotePeerId,
  }) {
    return HostStatus(
      myId: myId ?? this.myId,
      temporaryPassword: temporaryPassword ?? this.temporaryPassword,
      hasPermanentPassword: hasPermanentPassword ?? this.hasPermanentPassword,
      isHosting: isHosting ?? this.isHosting,
      serverConnected: serverConnected ?? this.serverConnected,
      serverUrl: serverUrl ?? this.serverUrl,
      isSelfHosted: isSelfHosted ?? this.isSelfHosted,
      activeClientCount: activeClientCount ?? this.activeClientCount,
      remoteConnected: remoteConnected ?? this.remoteConnected,
      remotePeerId: remotePeerId ?? this.remotePeerId,
    );
  }
}
