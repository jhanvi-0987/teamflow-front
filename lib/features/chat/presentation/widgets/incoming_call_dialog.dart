import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/call_session_model.dart';
import '../providers/call_providers.dart';
import '../screens/voice_call_screen.dart';
import '../screens/video_call_screen.dart';

class IncomingCallDialog extends ConsumerStatefulWidget {
  const IncomingCallDialog({super.key});

  @override
  ConsumerState<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends ConsumerState<IncomingCallDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callStateProvider);
    final isVideo = callState.callType == CallType.video;
    final callerName = callState.remoteUserName ?? 'Teammate';

    // Auto-dismiss dialog if caller ends call or state transitions away from incomingRinging
    ref.listen<CallState>(callStateProvider, (prev, next) {
      if (next.uiStatus != CallUIStatus.incomingRinging) {
        if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Call Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isVideo
                    ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                    : const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isVideo
                      ? const Color(0xFF6366F1).withValues(alpha: 0.5)
                      : const Color(0xFF10B981).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                    size: 16,
                    color: isVideo
                        ? const Color(0xFF818CF8)
                        : const Color(0xFF34D399),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isVideo
                          ? const Color(0xFF818CF8)
                          : const Color(0xFF34D399),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pulsing Avatar
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isVideo
                      ? const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        )
                      : AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: (isVideo
                              ? const Color(0xFF6366F1)
                              : AppColors.primary)
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  callerName.isNotEmpty ? callerName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Caller Name
            Text(
              callerName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              callState.channelName ?? 'TeamFlow Channel',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons (Decline / Accept)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline Button
                Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: () {
                        if (Navigator.of(context, rootNavigator: true).canPop()) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                        ref.read(callStateProvider.notifier).rejectCall();
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Accept Button
                Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: () async {
                        if (Navigator.of(context, rootNavigator: true).canPop()) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                        await ref
                            .read(callStateProvider.notifier)
                            .acceptCall();
                        final navContext = rootNavigatorKey.currentContext ?? context;
                        if (navContext.mounted) {
                          Navigator.of(navContext).push(
                            MaterialPageRoute(
                              builder: (_) => isVideo
                                  ? const VideoCallScreen()
                                  : const VoiceCallScreen(),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isVideo
                              ? Icons.videocam_rounded
                              : Icons.call_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
