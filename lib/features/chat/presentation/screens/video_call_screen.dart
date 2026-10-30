import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/call_providers.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  const VideoCallScreen({super.key});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
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
        statusText = 'Incoming video call...';
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
      backgroundColor: const Color(0xFF0A0F1D),
      body: Stack(
        children: [
          // Remote Participant Full-Screen Canvas
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1E293B),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Stylized mesh / remote video background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E1B4B),
                          const Color(0xFF0F172A),
                          const Color(0xFF1E293B),
                        ],
                      ),
                    ),
                  ),

                  // Remote Participant Centerpiece (Simulated Video Feed / Avatar fallback)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.35),
                              blurRadius: 28,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          remoteName.isNotEmpty
                              ? remoteName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        remoteName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (callState.isConnected)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: callState.isConnected
                                  ? const Color(0xFF34D399)
                                  : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Floating Picture-in-Picture (PiP) Local Camera Preview
          Positioned(
            top: 70,
            right: 18,
            child: Container(
              width: 105,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Local camera state
                  if (callState.isVideoEnabled)
                    Container(
                      color: const Color(0xFF334155),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              callState.isFrontCamera
                                  ? Icons.person_rounded
                                  : Icons.camera_alt_outlined,
                              color: Colors.white70,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              callState.isFrontCamera ? 'You' : 'Back Cam',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(
                          Icons.videocam_off_rounded,
                          color: Colors.white38,
                          size: 28,
                        ),
                      ),
                    ),

                  // PiP indicator badge
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        callState.isVideoEnabled ? 'Live' : 'Cam Off',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: callState.isVideoEnabled
                              ? const Color(0xFF10B981)
                              : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_rounded,
                              size: 15, color: Color(0xFF818CF8)),
                          const SizedBox(width: 6),
                          Text(
                            callState.channelName ?? 'Video Call',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),
            ),
          ),

          // Floating Bottom Controls Bar
          Positioned(
            bottom: 34,
            left: 20,
            right: 20,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Mute Mic Toggle
                  _VideoControlIcon(
                    icon: callState.isAudioMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    isActive: callState.isAudioMuted,
                    activeColor: const Color(0xFFEF4444),
                    onTap: () =>
                        ref.read(callStateProvider.notifier).toggleAudioMute(),
                  ),

                  // Camera Toggle (On/Off)
                  _VideoControlIcon(
                    icon: callState.isVideoEnabled
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    isActive: !callState.isVideoEnabled,
                    activeColor: const Color(0xFFEF4444),
                    onTap: () =>
                        ref.read(callStateProvider.notifier).toggleVideo(),
                  ),

                  // Switch Camera (Front/Back)
                  _VideoControlIcon(
                    icon: Icons.flip_camera_ios_rounded,
                    isActive: false,
                    onTap: () =>
                        ref.read(callStateProvider.notifier).switchCamera(),
                  ),

                  // Speaker Toggle
                  _VideoControlIcon(
                    icon: callState.isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    isActive: callState.isSpeakerOn,
                    activeColor: const Color(0xFF6366F1),
                    onTap: () =>
                        ref.read(callStateProvider.notifier).toggleSpeaker(),
                  ),

                  // Hang Up Button
                  InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () async {
                      await ref.read(callStateProvider.notifier).endCall();
                      if (context.mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_end_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
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
}

class _VideoControlIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;

  const _VideoControlIcon({
    required this.icon,
    this.isActive = false,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? (activeColor ?? AppColors.primary)
        : Colors.white.withValues(alpha: 0.12);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
