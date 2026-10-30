import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/message_attachment_model.dart';
import 'full_screen_image_viewer.dart';

class ChatAttachmentView extends StatelessWidget {
  final List<MessageAttachmentModel> attachments;
  final bool isMe;

  const ChatAttachmentView({
    super.key,
    required this.attachments,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final images = attachments.where((a) => a.isImage).toList();
    final docs = attachments.where((a) => !a.isImage).toList();

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (images.isNotEmpty) ...[
          _ImageGalleryView(images: images, isMe: isMe),
          if (docs.isNotEmpty) const SizedBox(height: 8),
        ],
        if (docs.isNotEmpty) ...[
          ...docs.map((doc) => _DocumentCard(attachment: doc, isMe: isMe)),
        ],
      ],
    );
  }
}

class _ImageGalleryView extends StatelessWidget {
  final List<MessageAttachmentModel> images;
  final bool isMe;

  const _ImageGalleryView({
    required this.images,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      final img = images.first;
      final fullUrl = img.resolveUrl();
      final heroTag = 'hero_attachment_${img.id}_${img.fileName}';

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => FullScreenImageViewer.show(
            context,
            imageUrl: fullUrl,
            title: img.fileName,
            heroTag: heroTag,
          ),
          child: Hero(
            tag: heroTag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 260,
                maxWidth: 280,
                minWidth: 140,
                minHeight: 120,
              ),
              child: Image.network(
                fullUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 160,
                    width: 200,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isMe ? Colors.white : AppColors.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, _) => Container(
                  height: 140,
                  width: 200,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image_outlined,
                            color: Colors.grey, size: 36),
                        const SizedBox(height: 4),
                        Text(
                          img.fileName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Multiple images (2 or 3+)
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: images.length > 4 ? 4 : images.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final img = images[index];
            final fullUrl = img.resolveUrl();
            final isLast = index == 3 && images.length > 4;
            final extraCount = images.length - 4;

            return GestureDetector(
              onTap: () => FullScreenImageViewer.show(
                context,
                imageUrl: fullUrl,
                title: img.fileName,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  if (isLast)
                    Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: Text(
                        '+$extraCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DocumentCard extends StatefulWidget {
  final MessageAttachmentModel attachment;
  final bool isMe;

  const _DocumentCard({
    required this.attachment,
    required this.isMe,
  });

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  bool _isDownloading = false;
  double? _downloadProgress;

  IconData _getFileIcon() {
    if (widget.attachment.isPdf) return Icons.picture_as_pdf_rounded;
    if (widget.attachment.isVideo) return Icons.video_file_rounded;
    if (widget.attachment.isAudio) return Icons.audio_file_rounded;
    final ext = widget.attachment.fileExtension.toLowerCase();
    if (['zip', 'rar', 'tar', 'gz', '7z'].contains(ext)) {
      return Icons.folder_zip_rounded;
    }
    if (['doc', 'docx', 'txt', 'rtf'].contains(ext)) {
      return Icons.description_rounded;
    }
    if (['xls', 'xlsx', 'csv'].contains(ext)) {
      return Icons.table_chart_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _getIconColor() {
    if (widget.attachment.isPdf) return const Color(0xFFEF4444);
    if (widget.attachment.isVideo) return const Color(0xFF8B5CF6);
    if (widget.attachment.isAudio) return const Color(0xFF10B981);
    final ext = widget.attachment.fileExtension.toLowerCase();
    if (['zip', 'rar', 'tar', 'gz', '7z'].contains(ext)) {
      return const Color(0xFFF59E0B);
    }
    if (['doc', 'docx'].contains(ext)) return const Color(0xFF2563EB);
    return AppColors.primary;
  }

  Future<void> _downloadAndOpen() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = null;
    });

    try {
      final tempDir = Directory.systemTemp;
      final fileName = widget.attachment.fileName.isNotEmpty
          ? widget.attachment.fileName
          : 'file_${DateTime.now().millisecondsSinceEpoch}';
      final savePath = '${tempDir.path}/$fileName';

      final fullUrl = widget.attachment.resolveUrl();
      final dio = Dio();
      await dio.download(
        fullUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      if (mounted) {
        final result = await OpenFilex.open(savePath);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message.isNotEmpty
                  ? result.message
                  : 'Downloaded to $savePath'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: widget.isMe
            ? Colors.white.withValues(alpha: 0.15)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isMe
              ? Colors.white.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _downloadAndOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.isMe
                        ? Colors.white.withValues(alpha: 0.2)
                        : iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileIcon(),
                    color: widget.isMe ? Colors.white : iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.attachment.fileName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.isMe
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.attachment.fileExtension} • ${widget.attachment.formattedSize}',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isMe
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (_isDownloading)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      value: _downloadProgress,
                      strokeWidth: 2.2,
                      color: widget.isMe ? Colors.white : AppColors.primary,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_circle_down_rounded,
                    color: widget.isMe
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Model representing an attachment being staged locally before sending
class StagedAttachment {
  final File file;
  final String fileName;
  final int fileSize;
  final bool isImage;
  double uploadProgress;
  bool isUploading;
  bool hasError;
  MessageAttachmentModel? uploadedModel;

  StagedAttachment({
    required this.file,
    required this.fileName,
    required this.fileSize,
    required this.isImage,
    this.uploadProgress = 0.0,
    this.isUploading = false,
    this.hasError = false,
    this.uploadedModel,
  });

  String get formattedSize {
    if (fileSize <= 0) return '';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Horizontal Staging Tray shown above Chat Input bar
class StagedAttachmentsTray extends StatelessWidget {
  final List<StagedAttachment> items;
  final ValueChanged<StagedAttachment> onRemove;
  final ValueChanged<StagedAttachment>? onRetry;

  const StagedAttachmentsTray({
    super.key,
    required this.items,
    required this.onRemove,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 74,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: item.hasError ? Colors.red.shade300 : Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: item.isImage
                            ? Image.file(
                                item.file,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Icon(
                                  Icons.insert_drive_file_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                      ),
                      Container(
                        color: Colors.grey.shade50,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Text(
                          item.fileName,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Uploading indicator overlay
              if (item.isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: item.uploadProgress > 0 ? item.uploadProgress : null,
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Error retry button
              if (item.hasError)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => onRetry?.call(item),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),

              // Remove 'X' button
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () => onRemove(item),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4B5563),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
