import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/agora_config.dart';

class VoiceCallScreen extends StatefulWidget {
  final String channelId; // Ticket ID digunakan sebagai channel
  final String currentUserId;
  final String otherUserName;

  const VoiceCallScreen({
    Key? key,
    required this.channelId,
    required this.currentUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  RtcEngine? _engine;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnected = false;
  bool _isJoining = true;
  String _callStatus = 'Menghubungkan...';
  Timer? _callTimer;
  int _callDuration = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Request microphone permission
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: AgoraConfig.appId));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _callStatus = 'Memanggil ${widget.otherUserName}...';
            _isJoining = false;
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _isConnected = true;
            _callStatus = 'Terhubung';
          });
          _startTimer();
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _isConnected = false;
            _callStatus = 'Panggilan berakhir';
          });
          _callTimer?.cancel();
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        },
        onError: (err, msg) {
          setState(() => _callStatus = 'Error: $msg');
          debugPrint('Agora Error: $err - $msg');
        },
      ),
    );

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableAudio();
    await _engine!.setEnableSpeakerphone(_isSpeakerOn);

    await _engine!.joinChannel(
      token: AgoraConfig.token ?? '',
      channelId: 'voice_${widget.channelId}',
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _callDuration++);
    });
  }

  String get _formattedDuration {
    final minutes = _callDuration ~/ 60;
    final seconds = _callDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine?.muteLocalAudioStream(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    _engine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  void _endCall() async {
    _callTimer?.cancel();
    await _engine?.leaveChannel();
    await _engine?.release();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseController.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white, size: 32),
                    onPressed: _endCall,
                  ),
                  const Spacer(),
                  Text(
                    'Panggilan Suara',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(),

            // Avatar + pulse animation
            ScaleTransition(
              scale: _isConnected ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16213E), Color(0xFF0F3460)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: _isConnected
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF1565C0),
                    width: 3,
                  ),
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white70, size: 64),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _isConnected ? _formattedDuration : _callStatus,
              style: TextStyle(
                color: _isConnected
                    ? const Color(0xFF4CAF50)
                    : Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),

            if (_isJoining) ...[
              const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            ],

            const Spacer(),

            // Controls
            Padding(
              padding: const EdgeInsets.only(bottom: 60, left: 40, right: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    onTap: _toggleMute,
                    isActive: _isMuted,
                    activeColor: Colors.orange,
                  ),
                  // End call button (bigger)
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE53935),
                      ),
                      child: const Icon(Icons.call_end_rounded,
                          color: Colors.white, size: 36),
                    ),
                  ),
                  _buildControlButton(
                    icon: _isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                    onTap: _toggleSpeaker,
                    isActive: _isSpeakerOn,
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color activeColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? activeColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              border: Border.all(
                color: isActive ? activeColor : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Icon(icon,
                color: isActive ? activeColor : Colors.white70, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }
}
