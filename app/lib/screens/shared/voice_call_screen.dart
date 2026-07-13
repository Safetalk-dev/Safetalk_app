import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/tokens.dart';

class VoiceCallScreen extends StatefulWidget {
  final String channelName;
  final String token;
  final String appId;

  const VoiceCallScreen({
    super.key,
    required this.channelName,
    required this.token,
    required this.appId,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: widget.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user \${connection.localUid} joined");
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user \$remoteUid joined");
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("remote user \$remoteUid left channel");
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint('[onTokenPrivilegeWillExpire] connection: \${connection.toJson()}, token: \$token');
        },
      ),
    );

    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  void _onToggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _onCallEnd() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeTalkTheme.bgMidnight,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 60,
              backgroundColor: SafeTalkTheme.brandSage.withValues(alpha: 0.2),
              child: const Icon(Icons.person_rounded, size: 60, color: SafeTalkTheme.brandSage),
            ),
            const SizedBox(height: 24),
            Text(
              'Secure Voice Session',
              style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              _isJoined ? 'Connected • Encrypted' : 'Connecting...',
              style: SafeTalkTheme.bodyStyle(color: _isJoined ? SafeTalkTheme.brandSage : SafeTalkTheme.textSecondary),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCallAction(
                  icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: _isMuted ? SafeTalkTheme.textSecondary : SafeTalkTheme.brandSage,
                  onPressed: _onToggleMute,
                ),
                const SizedBox(width: 32),
                _buildCallAction(
                  icon: Icons.call_end_rounded,
                  color: SafeTalkTheme.brandTerracotta,
                  onPressed: _onCallEnd,
                  size: 64,
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCallAction({required IconData icon, required Color color, required VoidCallback onPressed, double size = 56}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}
