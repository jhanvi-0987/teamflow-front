import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/call_providers.dart';
import 'video_call_screen.dart';

class VoiceCallScreen extends ConsumerStatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callStateProvider);
    final remoteName = callState.remoteUserName ?? 'Teammate';

    // Auto-pop when call ends
    ref.listen(callStateProvider, (prev, next) {
      if (prev?.uiStatus != CallUIStatus.ended &&
          next.uiStatus == CallUIStatus.ended) {
        final nav = Navigator.of(context);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted && nav.canPop()) {
            nav.pop();
          }
        });
      }
    });

    String statusText;
    switch (callState.uiStatus) {
      case CallUIStatus.outgoingRinging:
        statusText = 'Ringing...';
        break;
      case CallUIStatus.incomingRinging:
        statusText = 'Incoming call...';
        break;
      case CallUIStatus.connected:
        statusText = callState.formattedDuration;
        break;
      case CallUIStatus.ended:
        statusText = 'Call ended';
        break;
      case CallUIStatus.idle:
        statusText = 'Disconnected';
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded,
                            size: 12, color: Color(0xFF34D399)),
                        const SizedBox(width: 4),
                        Text(
                          callState.channelName ?? 'TeamFlow Audio',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // balance
                ],
              ),
            ),

            const Spacer(),

            // Pulsing Avatar with Wave Rings
            Stack(
              alignment: Alignment.center,
              children: [
                if (callState.isConnected)
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return Container(
                        width: 160 + (_waveController.value * 50),
                        height: 160 + (_waveController.value * 50),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF6366F1).withValues(
                              alpha: (1.0 - _waveController.value) * 0.4,
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    remoteName.isNotEmpty ? remoteName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // User Name
            Text(
              remoteName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Status / Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (callState.isConnected)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: callState.isConnected
                        ? const Color(0xFF34D399)
                        : Colors.white60,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Control Buttons
            Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Mute Mic Button
                  _CallCircleButton(
                    icon: callState.isAudioMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    label: callState.isAudioMuted ? 'Unmute' : 'Mute',
                    isActive: callState.isAudioMuted,
                    activeColor: const Color(0xFFEF4444),
                    onTap: () =>
                        ref.read(callStateProvider.notifier).toggleAudioMute(),
                  ),

                  // Speaker Button
                  _CallCircleButton(
                    icon: callState.isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: 'Speaker',
                    isActive: callState.isSpeakerOn,
                    activeColor: const Color(0xFF6366F1),
                    onTap: () =>
                        ref.read(callStateProvider.notifier).toggleSpeaker(),
                  ),

                  // Switch to Video
                  _CallCircleButton(
                    icon: Icons.videocam_rounded,
                    label: 'Video',
                    isActive: false,
                    onTap: () {
                      ref.read(callStateProvider.notifier).toggleVideo();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const VideoCallScreen(),
                        ),
                      );
                    },
                  ),

                  // End Call Button
                  _CallCircleButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    isDestructive: true,
                    onTap: () async {
                      await ref.read(callStateProvider.notifier).endCall();
                      if (context.mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final Color? activeColor;
  final VoidCallback onTap;

  const _CallCircleButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isDestructive = false,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color iconColor;

    if (isDestructive) {
      bg = const Color(0xFFEF4444);
      iconColor = Colors.white;
    } else if (isActive) {
      bg = activeColor ?? AppColors.primary;
      iconColor = Colors.white;
    } else {
      bg = Colors.white.withValues(alpha: 0.12);
      iconColor = Colors.white;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
