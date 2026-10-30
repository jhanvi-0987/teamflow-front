import 'package:equatable/equatable.dart';
import '../../../../core/network/api_endpoints.dart';

class MessageAttachmentModel extends Equatable {
  final String id;
  final String? messageId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final int? width;
  final int? height;
  final DateTime? createdAt;

  const MessageAttachmentModel({
    required this.id,
    this.messageId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    this.width,
    this.height,
    this.createdAt,
  });

  bool get isImage =>
      fileType.toLowerCase().startsWith('image/') ||
      _hasImageExtension(fileName);

  bool get isPdf =>
      fileType.toLowerCase().contains('pdf') ||
      fileName.toLowerCase().endsWith('.pdf');

  bool get isVideo => fileType.toLowerCase().startsWith('video/');

  bool get isAudio => fileType.toLowerCase().startsWith('audio/');

  static bool _hasImageExtension(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.heic');
  }

  String get fileExtension {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < fileName.length - 1) {
      return fileName.substring(dotIndex + 1).toUpperCase();
    }
    return '';
  }

  String get formattedSize {
    if (fileSize <= 0) return '';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String resolveUrl([String? base]) {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }
    final effectiveBase = base ?? ApiEndpoints.baseUrl;
    final serverOrigin = effectiveBase.replaceAll(RegExp(r'/api/v1/?$'), '');
    final cleanPath = fileUrl.startsWith('/') ? fileUrl : '/$fileUrl';
    return '$serverOrigin$cleanPath';
  }

  factory MessageAttachmentModel.fromJson(Map<String, dynamic> json) {
    return MessageAttachmentModel(
      id: json['id'] as String? ?? '',
      messageId: json['messageId'] as String?,
      fileName: json['fileName'] as String? ?? 'attachment',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileType: json['fileType'] as String? ?? 'application/octet-stream',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (messageId != null) 'messageId': messageId,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'fileSize': fileSize,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  MessageAttachmentModel copyWith({
    String? id,
    String? messageId,
    String? fileName,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    int? width,
    int? height,
    DateTime? createdAt,
  }) {
    return MessageAttachmentModel(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        messageId,
        fileName,
        fileUrl,
        fileType,
        fileSize,
        width,
        height,
        createdAt,
      ];
}
