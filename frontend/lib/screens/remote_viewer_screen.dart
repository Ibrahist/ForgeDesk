import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../models/remote_session.dart';
import '../services/forgedesk_bridge.dart';
import '../widgets/glass_card.dart';
import '../widgets/session_toolbar.dart';

class RemoteViewerScreen extends StatefulWidget {
  final ForgeDeskBridgeService bridge;

  const RemoteViewerScreen({
    super.key,
    required this.bridge,
  });

  @override
  State<RemoteViewerScreen> createState() => _RemoteViewerScreenState();
}

class _RemoteViewerScreenState extends State<RemoteViewerScreen> {
  final GlobalKey _viewportKey = GlobalKey();
  final TextEditingController _chatInputCtrl = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _chatInputCtrl.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _sendNormalizedMouse(Offset globalPos, {int button = 0, bool? isDown}) {
    final renderBox = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = renderBox.globalToLocal(globalPos);
    final size = renderBox.size;
    if (size.width <= 0 || size.height <= 0) return;

    final normX = (localPos.dx / size.width).clamp(0.0, 1.0);
    final normY = (localPos.dy / size.height).clamp(0.0, 1.0);

    final eventMap = <String, dynamic>{
      'x': normX,
      'y': normY,
    };

    if (isDown == null) {
      widget.bridge.sendInput({
        'event': 'MouseMove',
        'params': eventMap,
      });
    } else {
      String btn = 'Left';
      if (button == kSecondaryMouseButton) btn = 'Right';
      if (button == kMiddleMouseButton) btn = 'Middle';

      widget.bridge.sendInput({
        'event': isDown ? 'MouseDown' : 'MouseUp',
        'params': {
          'button': btn,
          'x': normX,
          'y': normY,
        },
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final isDown = event is KeyDownEvent;
    final isUp = event is KeyUpEvent;

    if (isDown || isUp) {
      widget.bridge.sendInput({
        'event': isDown ? 'KeyDown' : 'KeyUp',
        'params': {
          'key_code': event.logicalKey.keyId,
          'key': event.logicalKey.keyLabel,
        },
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _sendChat() {
    final text = _chatInputCtrl.text.trim();
    if (text.isNotEmpty) {
      widget.bridge.sendChat(text);
      _chatInputCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.bridge,
      builder: (context, _) {
        final session = widget.bridge.remoteSession;

        // If disconnected, return to home
        if (!session.isConnected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Focus(
            focusNode: _keyboardFocusNode,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: Stack(
              children: [
                // Remote Screen Canvas with Input Capturing
                Positioned.fill(
                  child: Listener(
                    onPointerHover: (e) => _sendNormalizedMouse(e.position),
                    onPointerDown: (e) => _sendNormalizedMouse(e.position, button: e.buttons, isDown: true),
                    onPointerUp: (e) => _sendNormalizedMouse(e.position, button: e.buttons, isDown: false),
                    onPointerSignal: (signal) {
                      if (signal is PointerScrollEvent) {
                        widget.bridge.sendInput({
                          'event': 'MouseScroll',
                          'params': {
                            'delta_x': signal.scrollDelta.dx,
                            'delta_y': signal.scrollDelta.dy,
                          },
                        });
                      }
                    },
                    child: Center(
                      child: Container(
                        key: _viewportKey,
                        width: double.infinity,
                        height: double.infinity,
                        color: const Color(0xFF070A10),
                        child: session.latestFrameBytes != null
                            ? Image.memory(
                                session.latestFrameBytes!,
                                fit: _getBoxFit(session.scaleMode),
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.low,
                              )
                            : _buildWaitingDesktopScreen(session),
                      ),
                    ),
                  ),
                ),

                // Floating Top Session Toolbar
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SessionToolbar(
                      session: session,
                      onToggleFullscreen: widget.bridge.toggleFullscreen,
                      onScaleModeChanged: widget.bridge.updateScaleMode,
                      onSendCtrlAltDel: () {
                        widget.bridge.sendInput({
                          'event': 'Action',
                          'params': {'action_type': 'CtrlAltDel'},
                        });
                      },
                      onSendLock: () {
                        widget.bridge.sendInput({
                          'event': 'Action',
                          'params': {'action_type': 'LockWorkstation'},
                        });
                      },
                      onToggleChat: widget.bridge.toggleChat,
                      onDisconnect: widget.bridge.disconnectRemote,
                    ),
                  ),
                ),

                // In-Session Live Chat Drawer
                if (session.isChatOpen)
                  Positioned(
                    top: 80,
                    right: 24,
                    bottom: 24,
                    width: 340,
                    child: _buildChatDrawer(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxFit _getBoxFit(RemoteViewScaleMode mode) {
    switch (mode) {
      case RemoteViewScaleMode.original:
        return BoxFit.none;
      case RemoteViewScaleMode.stretch:
        return BoxFit.fill;
      case RemoteViewScaleMode.fit:
        return BoxFit.contain;
    }
  }

  Widget _buildWaitingDesktopScreen(RemoteSessionState session) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ForgeColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: ForgeColors.primary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: ForgeColors.primary.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: ForgeColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Connected to ${session.remotePeerId}',
            style: const TextStyle(
              color: ForgeColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Establishing low-latency encrypted desktop stream...',
            style: TextStyle(
              color: ForgeColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatDrawer() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.chat_bubble_rounded, size: 16, color: ForgeColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Session Chat',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ForgeColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: widget.bridge.toggleChat,
                icon: const Icon(Icons.close_rounded, size: 18, color: ForgeColors.textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(height: 20),

          // Chat Messages List
          Expanded(
            child: widget.bridge.chatMessages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet.\nType below to message the host.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ForgeColors.textMuted, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.bridge.chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = widget.bridge.chatMessages[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: msg.isMe ? ForgeColors.primary.withValues(alpha: 0.2) : ForgeColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: msg.isMe ? ForgeColors.primary.withValues(alpha: 0.4) : ForgeColors.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.sender,
                                style: TextStyle(
                                  color: msg.isMe ? ForgeColors.primary : ForgeColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg.text,
                                style: const TextStyle(color: ForgeColors.textPrimary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 10),

          // Chat Input Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatInputCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendChat(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendChat,
                icon: const Icon(Icons.send_rounded, color: ForgeColors.primary, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: ForgeColors.surfaceLight,
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
