class AppConstants {
  static const String appName = 'ForgeDesk';
  static const String appVersion = 'v0.1.0-alpha';
  static const String tagline = 'Open-Source Self-Hosted Remote Desktop';

  // Network Defaults
  static const int defaultBridgePort = 48123;
  static const String defaultRendezvousHost = '127.0.0.1:21115';
  static const String defaultRelayHost = '127.0.0.1:21117';
  static const String defaultPublicRendezvous = 'rendezvous.forgedesk.io:21115';
  static const String defaultPublicRelay = 'relay.forgedesk.io:21117';

  // Local storage keys
  static const String keyRecentSessions = 'forgedesk_recent_sessions';
  static const String keySettings = 'forgedesk_client_settings';
  static const String keyPermanentPassword = 'forgedesk_permanent_password';
}
