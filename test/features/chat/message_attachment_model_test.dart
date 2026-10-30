import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_endpoints.dart';
import 'package:mobile/features/chat/domain/models/message_attachment_model.dart';
import 'package:mobile/features/chat/domain/models/message_model.dart';

void main() {
  group('MessageAttachmentModel', () {
    test('parses json correctly and handles getters', () {
      final json = {
        'id': 'att-123',
        'messageId': 'msg-456',
        'fileName': 'quarterly_report.pdf',
        'fileUrl': '/uploads/attachments/quarterly_report.pdf',
        'fileType': 'application/pdf',
        'fileSize': 2621440, // 2.5 MB
        'width': null,
        'height': null,
        'createdAt': '2026-10-30T10:00:00.000Z',
      };

      final model = MessageAttachmentModel.fromJson(json);

      expect(model.id, equals('att-123'));
      expect(model.messageId, equals('msg-456'));
      expect(model.fileName, equals('quarterly_report.pdf'));
      expect(model.fileExtension, equals('PDF'));
      expect(model.isPdf, isTrue);
      expect(model.isImage, isFalse);
      expect(model.formattedSize, equals('2.5 MB'));
      expect(
        model.resolveUrl('http://192.168.1.10:3000/api/v1'),
        equals('http://192.168.1.10:3000/uploads/attachments/quarterly_report.pdf'),
      );
    });

    test('detects images correctly and formats size in KB', () {
      final img = MessageAttachmentModel(
        id: 'img-1',
        fileName: 'screenshot.png',
        fileUrl: 'https://cdn.example.com/screenshot.png',
        fileType: 'image/png',
        fileSize: 51200, // 50 KB
      );

      expect(img.isImage, isTrue);
      expect(img.isPdf, isFalse);
      expect(img.formattedSize, equals('50.0 KB'));
      expect(img.resolveUrl(), equals('https://cdn.example.com/screenshot.png'));
    });

    test('serializes to json correctly', () {
      final model = MessageAttachmentModel(
        id: 'att-1',
        messageId: 'msg-1',
        fileName: 'photo.jpg',
        fileUrl: '/uploads/attachments/photo.jpg',
        fileType: 'image/jpeg',
        fileSize: 1024,
      );

      final json = model.toJson();
      expect(json['id'], equals('att-1'));
      expect(json['fileName'], equals('photo.jpg'));
      expect(json['fileType'], equals('image/jpeg'));
    });
  });

  group('MessageModel attachments', () {
    test('serializes and deserializes attachments in MessageModel', () {
      final messageJson = {
        'id': 'msg-999',
        'channelId': 'chan-1',
        'senderId': 'user-1',
        'sender': {'name': 'Alice', 'email': 'alice@example.com'},
        'content': 'Here are the design assets',
        'attachments': [
          {
            'id': 'att-1',
            'messageId': 'msg-999',
            'fileName': 'mockup.png',
            'fileUrl': '/uploads/attachments/mockup.png',
            'fileType': 'image/png',
            'fileSize': 1048576,
          },
        ],
        'status': 'sent',
        'createdAt': '2026-10-30T11:00:00.000Z',
      };

      final message = MessageModel.fromJson(messageJson);
      expect(message.hasAttachments, isTrue);
      expect(message.attachments.length, equals(1));
      expect(message.attachments.first.fileName, equals('mockup.png'));
      expect(message.attachments.first.isImage, isTrue);

      final exported = message.toJson();
      expect(exported['attachments'], isA<List>());
      expect((exported['attachments'] as List).length, equals(1));
    });

    test('hasAttachments is false when attachments empty', () {
      final message = MessageModel(
        id: 'msg-1',
        channelId: 'chan-1',
        senderId: 'user-1',
        senderName: 'Bob',
        senderEmail: 'bob@example.com',
        content: 'Hello team',
        createdAt: DateTime.now(),
      );

      expect(message.hasAttachments, isFalse);
      expect(message.attachments, isEmpty);
    });
  });
}

