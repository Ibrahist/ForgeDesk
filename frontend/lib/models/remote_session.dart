import 'dart:typed_data';

enum RemoteViewScaleMode { fit, stretch, original }

class RemoteSessionState {
  final String remotePeerId;
  final String alias;
  final bool isConnected;
  final int width;
  final int height;
  final Uint8List? latestFrameBytes;
  final double fps;
  final int latencyMs;
  final int bitrateKbps;
  final String quality;
  final RemoteViewScaleMode scaleMode;
  final bool isFullscreen;
  final bool isChatOpen;

  RemoteSessionState({
    required this.remotePeerId,
    required this.alias,
    required this.isConnected,
    this.width = 1920,
    this.height = 1080,
    this.latestFrameBytes,
    this.fps = 0.0,
    this.latencyMs = 0,
    this.bitrateKbps = 0,
    this.quality = 'balanced',
    this.scaleMode = RemoteViewScaleMode.fit,
    this.isFullscreen = false,
    this.isChatOpen = false,
  });

  RemoteSessionState copyWith({
    String? remotePeerId,
    String? alias,
    bool? isConnected,
    int? width,
    int? height,
    Uint8List? latestFrameBytes,
    double? fps,
    int? latencyMs,
    int? bitrateKbps,
    String? quality,
    RemoteViewScaleMode? scaleMode,
    bool? isFullscreen,
    bool? isChatOpen,
  }) {
    return RemoteSessionState(
      remotePeerId: remotePeerId ?? this.remotePeerId,
      alias: alias ?? this.alias,
      isConnected: isConnected ?? this.isConnected,
      width: width ?? this.width,
      height: height ?? this.height,
      latestFrameBytes: latestFrameBytes ?? this.latestFrameBytes,
      fps: fps ?? this.fps,
      latencyMs: latencyMs ?? this.latencyMs,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      quality: quality ?? this.quality,
      scaleMode: scaleMode ?? this.scaleMode,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isChatOpen: isChatOpen ?? this.isChatOpen,
    );
  }
}

class RecentSessionItem {
  final String id;
  final String alias;
  final DateTime lastConnected;
  final String osType; // "Windows", "Linux", "macOS", "Android"
  final bool isFavorite;

  RecentSessionItem({
    required this.id,
    required this.alias,
    required this.lastConnected,
    required this.osType,
    this.isFavorite = false,
  });

  factory RecentSessionItem.fromJson(Map<String, dynamic> json) {
    return RecentSessionItem(
      id: json['id'] as String,
      alias: json['alias'] as String,
      lastConnected: DateTime.parse(json['lastConnected'] as String),
      osType: json['osType'] as String? ?? 'Windows',
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alias': alias,
      'lastConnected': lastConnected.toIso8601String(),
      'osType': osType,
      'isFavorite': isFavorite,
    };
  }
}
