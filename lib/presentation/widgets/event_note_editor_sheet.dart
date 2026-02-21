import 'dart:convert';
import 'dart:typed_data';

import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/presentation/theme/walnie_tokens.dart';
import 'package:baby_tracker/presentation/utils/event_image_codec.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class EventNoteDraft {
  const EventNoteDraft({required this.note, required this.attachments});

  final String note;
  final List<EventAttachment> attachments;
}

Future<EventNoteDraft?> showEventNoteEditorSheet(
  BuildContext context, {
  required String initialNote,
  required List<EventAttachment> initialAttachments,
  int maxAttachments = 3,
}) {
  return showModalBottomSheet<EventNoteDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    builder: (context) {
      return _EventNoteEditorSheet(
        initialNote: initialNote,
        initialAttachments: initialAttachments,
        maxAttachments: maxAttachments,
      );
    },
  );
}

class _EventNoteEditorSheet extends StatefulWidget {
  const _EventNoteEditorSheet({
    required this.initialNote,
    required this.initialAttachments,
    required this.maxAttachments,
  });

  final String initialNote;
  final List<EventAttachment> initialAttachments;
  final int maxAttachments;

  @override
  State<_EventNoteEditorSheet> createState() => _EventNoteEditorSheetState();
}

class _EventNoteEditorSheetState extends State<_EventNoteEditorSheet> {
  late final TextEditingController _noteController;
  late final List<EventAttachment> _attachments;
  final ImagePicker _imagePicker = ImagePicker();
  bool _loadingImage = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
    _attachments = List<EventAttachment>.from(widget.initialAttachments);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: WalnieTokens.spacingLg,
          right: WalnieTokens.spacingLg,
          top: WalnieTokens.spacingSm,
          bottom:
              MediaQuery.of(context).viewInsets.bottom + WalnieTokens.spacingXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('备注', style: theme.textTheme.titleLarge)),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: WalnieTokens.spacingSm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadingImage ? null : _pickFromCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('拍照'),
                  ),
                ),
                const SizedBox(width: WalnieTokens.spacingSm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadingImage ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('相册'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: WalnieTokens.spacingSm),
            Text(
              '图片 ${_attachments.length}/${widget.maxAttachments}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: WalnieTokens.spacingSm),
            if (_attachments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(WalnieTokens.spacingMd),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text('还没有图片', style: theme.textTheme.bodyMedium),
              )
            else
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  separatorBuilder: (_, index) =>
                      const SizedBox(width: WalnieTokens.spacingSm),
                  itemBuilder: (context, index) {
                    final attachment = _attachments[index];
                    return _AttachmentPreview(
                      attachment: attachment,
                      onDelete: () => _removeAttachment(index),
                    );
                  },
                ),
              ),
            const SizedBox(height: WalnieTokens.spacingSm),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '备注文本（可选）'),
            ),
            const SizedBox(height: WalnieTokens.spacingMd),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    EventNoteDraft(
                      note: _noteController.text.trim(),
                      attachments: List<EventAttachment>.from(_attachments),
                    ),
                  );
                },
                child: const Text('保存备注'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _pickFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_attachments.length >= widget.maxAttachments) {
      _showTip('最多上传 ${widget.maxAttachments} 张图片');
      return;
    }

    setState(() {
      _loadingImage = true;
    });

    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 70,
      );
      if (file == null) {
        return;
      }

      final encoded = await encodeEventImage(file);
      final attachment = EventAttachment(
        id: const Uuid().v4(),
        mimeType: encoded.mimeType,
        base64: encoded.base64,
        createdAt: DateTime.now().toIso8601String(),
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _attachments.add(attachment);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showTip('图片处理失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _loadingImage = false;
        });
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _showTip(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.attachment, required this.onDelete});

  final EventAttachment attachment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
          child: Container(
            width: 92,
            height: 92,
            color: Colors.black.withValues(alpha: 0.08),
            child: Image.memory(
              _decodedBytes(attachment.base64),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Uint8List _decodedBytes(String raw) {
    return base64Decode(raw);
  }
}
