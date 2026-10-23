import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';
import '../models/chat_message.dart';
import '../models/client_settings.dart';
import '../models/host_status.dart';
import '../models/remote_session.dart';

class ForgeDeskBridgeService extends ChangeNotifier {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _mockStreamTimer;
  bool _isConnecting = false;

  HostStatus _status = HostStatus.initial();
  HostStatus get status => _status;

  RemoteSessionState _remoteSession = RemoteSessionState(
    remotePeerId: '',
    alias: '',
    isConnected: false,
  );
  RemoteSessionState get remoteSession => _remoteSession;

  final List<ChatMessage> _chatMessages = [];
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  bool _isBridgeActive = false;
  bool get isBridgeActive => _isBridgeActive;

  ForgeDeskBridgeService() {
    initBridge();
  }

  void initBridge() {
    connectToDaemon();
  }

  Future<void> connectToDaemon() async {
    if (_isConnecting) return;
    _isConnecting = true;

    final uri = Uri.parse('ws://127.0.0.1:${AppConstants.defaultBridgePort}');
    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _isBridgeActive = true;
      _isConnecting = false;
      _stopMockSimulation();
      notifyListeners();

      _channel!.stream.listen(
        (data) {
          _handleDaemonMessage(data.toString());
        },
        onDone: () {
          _isBridgeActive = false;
          _scheduleReconnect();
          notifyListeners();
        },
        onError: (err) {
          _isBridgeActive = false;
          _scheduleReconnect();
          notifyListeners();
        },
      );

      // Request initial status
      sendCommand({'cmd': 'GetStatus'});
    } catch (_) {
      _isBridgeActive = false;
      _isConnecting = false;
      _startMockSimulation();
      _scheduleReconnect();
      notifyListeners();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      connectToDaemon();
    });
  }

  void sendCommand(Map<String, dynamic> command) {
    if (_channel != null && _isBridgeActive) {
      try {
        _channel!.sink.add(jsonEncode(command));
        return;
      } catch (_) {}
    }

    // If bridge is not running, handle command locally in fallback mode
    _handleCommandFallback(command);
  }

  void _handleDaemonMessage(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final eventType = decoded['event'] as String?;
      final data = decoded['data'];

      switch (eventType) {
        case 'StatusUpdate':
          if (data is Map<String, dynamic>) {
            _status = HostStatus.fromJson(data);
            notifyListeners();
          }
          break;
        case 'RemoteFrame':
          if (data is Map<String, dynamic>) {
            final b64 = data['payload_base64'] as String?;
            if (b64 != null) {
              final bytes = base64Decode(b64);
              _remoteSession = _remoteSession.copyWith(
                latestFrameBytes: bytes,
                width: data['width'] as int? ?? _remoteSession.width,
                height: data['height'] as int? ?? _remoteSession.height,
              );
              notifyListeners();
            }
          }
          break;
        case 'RemoteConnected':
          if (data is Map<String, dynamic>) {
            _remoteSession = _remoteSession.copyWith(
              isConnected: true,
              remotePeerId: data['peer_id'] as String? ?? 'Remote Desk',
            );
            notifyListeners();
          }
          break;
        case 'RemoteDisconnected':
          _remoteSession = _remoteSession.copyWith(
            isConnected: false,
            latestFrameBytes: null,
          );
          notifyListeners();
          break;
        case 'TelemetryUpdated':
          if (data is Map<String, dynamic>) {
            _remoteSession = _remoteSession.copyWith(
              fps: (data['fps'] as num?)?.toDouble() ?? 0.0,
              latencyMs: data['latency_ms'] as int? ?? 15,
              bitrateKbps: data['bitrate_kbps'] as int? ?? 1200,
            );
            notifyListeners();
          }
          break;
        case 'ChatReceived':
          if (data is Map<String, dynamic>) {
            _chatMessages.add(ChatMessage.fromJson(data));
            notifyListeners();
          }
          break;
      }
    } catch (e) {
      debugPrint('Error parsing daemon message: $e');
    }
  }

  // Fallback simulator for headless preview or before daemon starts
  void _startMockSimulation() {
    _mockStreamTimer?.cancel();
    _mockStreamTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_remoteSession.isConnected && !_isBridgeActive) {
        _remoteSession = _remoteSession.copyWith(
          fps: 58.5 + (timer.tick % 4) * 0.4,
          latencyMs: 14 + (timer.tick % 3),
          bitrateKbps: 2450 + (timer.tick % 100),
        );
        notifyListeners();
      }
    });
  }

  void _stopMockSimulation() {
    _mockStreamTimer?.cancel();
    _mockStreamTimer = null;
  }

  void _handleCommandFallback(Map<String, dynamic> command) {
    final cmd = command['cmd'] as String?;
    final data = command['data'];

    if (cmd == 'RegeneratePassword') {
      const chars = 'abcdefghijkmnpqrstuvwxyz23456789';
      final newPass = List.generate(6, (i) => chars[(DateTime.now().microsecond + i * 7) % chars.length]).join();
      _status = _status.copyWith(temporaryPassword: newPass);
      notifyListeners();
    } else if (cmd == 'StartHost') {
      _status = _status.copyWith(isHosting: true);
      notifyListeners();
    } else if (cmd == 'StopHost') {
      _status = _status.copyWith(isHosting: false);
      notifyListeners();
    } else if (cmd == 'ConnectRemote') {
      if (data is Map<String, dynamic>) {
        final targetId = data['remote_id'] as String? ?? 'Remote Desk';
        _remoteSession = RemoteSessionState(
          remotePeerId: targetId,
          alias: 'Remote Station ($targetId)',
          isConnected: true,
          fps: 60.0,
          latencyMs: 16,
          bitrateKbps: 2840,
        );
        _startMockSimulation();
        notifyListeners();
      }
    } else if (cmd == 'DisconnectRemote') {
      _remoteSession = _remoteSession.copyWith(isConnected: false);
      notifyListeners();
    } else if (cmd == 'SendChat') {
      if (data is Map<String, dynamic>) {
        final text = data['message'] as String? ?? '';
        final msg = ChatMessage(
          sender: 'You',
          text: text,
          timestamp: DateTime.now(),
          isMe: true,
        );
        _chatMessages.add(msg);
        notifyListeners();
      }
    }
  }

  // High level UI actions
  void toggleHosting() {
    if (_status.isHosting) {
      sendCommand({'cmd': 'StopHost'});
    } else {
      sendCommand({'cmd': 'StartHost'});
    }
  }

  void regeneratePassword() {
    sendCommand({'cmd': 'RegeneratePassword'});
  }

  void connectRemote(String targetId, String password, {String quality = 'balanced'}) {
    sendCommand({
      'cmd': 'ConnectRemote',
      'data': {
        'remote_id': targetId,
        'password': password,
        'quality': quality,
      },
    });
  }

  void disconnectRemote() {
    sendCommand({'cmd': 'DisconnectRemote'});
  }

  void sendInput(Map<String, dynamic> inputEvent) {
    sendCommand({
      'cmd': 'SendInput',
      'data': inputEvent,
    });
  }

  void sendChat(String message) {
    sendCommand({
      'cmd': 'SendChat',
      'data': {'message': message},
    });
  }

  void sendClipboard(String text) {
    sendCommand({
      'cmd': 'SendClipboard',
      'data': {'text': text},
    });
  }

  void updateSettings(ClientSettings newSettings) {
    sendCommand({
      'cmd': 'UpdateSettings',
      'data': newSettings.toJson(),
    });
    _status = _status.copyWith(
      serverUrl: newSettings.rendezvousServer,
      isSelfHosted: newSettings.isSelfHosted,
    );
    notifyListeners();
  }

  void updateScaleMode(RemoteViewScaleMode mode) {
    _remoteSession = _remoteSession.copyWith(scaleMode: mode);
    notifyListeners();
  }

  void toggleFullscreen() {
    _remoteSession = _remoteSession.copyWith(isFullscreen: !_remoteSession.isFullscreen);
    notifyListeners();
  }

  void toggleChat() {
    _remoteSession = _remoteSession.copyWith(isChatOpen: !_remoteSession.isChatOpen);
    notifyListeners();
  }

  @override
  void dispose() {
    _mockStreamTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
