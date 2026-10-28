import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/domain/models/message_model.dart';

// Standalone widget replicating _MessageBubble tick rendering for direct widget testing
Widget buildStatusTicksWidget({
  required String status,
  required bool isMe,
}) {
  if (!isMe) return const SizedBox.shrink();

  switch (status) {
    case 'read':
      return const Icon(
        Icons.done_all_rounded,
        key: Key('read_ticks'),
        size: 15,
        color: Color(0xFF38BDF8),
      );
    case 'delivered':
      return Icon(
        Icons.done_all_rounded,
        key: const Key('delivered_ticks'),
        size: 15,
        color: Colors.white.withValues(alpha: 0.7),
      );
    case 'sent':
    default:
      return Icon(
        Icons.check_rounded,
        key: const Key('sent_ticks'),
        size: 14,
        color: Colors.white.withValues(alpha: 0.7),
      );
  }
}

void main() {
  group('Message Status Ticks UI Tests', () {
    testWidgets('shows one tick mark when status is sent (offline)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildStatusTicksWidget(status: 'sent', isMe: true),
          ),
        ),
      );

      expect(find.byKey(const Key('sent_ticks')), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      final icon = tester.widget<Icon>(find.byKey(const Key('sent_ticks')));
      expect(icon.color, equals(Colors.white.withValues(alpha: 0.7)));
    });

    testWidgets('shows two tick marks with gray color when status is delivered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildStatusTicksWidget(status: 'delivered', isMe: true),
          ),
        ),
      );

      expect(find.byKey(const Key('delivered_ticks')), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);

      final icon = tester.widget<Icon>(find.byKey(const Key('delivered_ticks')));
      expect(icon.color, equals(Colors.white.withValues(alpha: 0.7)));
    });

    testWidgets('shows double tick mark with blue color when status is read', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildStatusTicksWidget(status: 'read', isMe: true),
          ),
        ),
      );

      expect(find.byKey(const Key('read_ticks')), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);

      final icon = tester.widget<Icon>(find.byKey(const Key('read_ticks')));
      expect(icon.color, equals(const Color(0xFF38BDF8)));
    });

    testWidgets('does not show tick marks when message is from another user (!isMe)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildStatusTicksWidget(status: 'read', isMe: false),
          ),
        ),
      );

      expect(find.byKey(const Key('read_ticks')), findsNothing);
      expect(find.byKey(const Key('delivered_ticks')), findsNothing);
      expect(find.byKey(const Key('sent_ticks')), findsNothing);
    });
  });
}

