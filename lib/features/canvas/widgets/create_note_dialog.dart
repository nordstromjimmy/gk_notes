import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gk_notes/data/models/image_to_attach.dart';
import 'package:gk_notes/theme/note_colors.dart';
import 'package:path/path.dart' as p;

import 'note_dialog_shared.dart';

class CreateNoteResult {
  final String title;
  final String text;
  final int colorValue;
  final List<ImageToAttach> images;
  final List<String> videoPaths;
  final List<String> pdfPaths;

  const CreateNoteResult(
    this.title,
    this.text,
    this.colorValue,
    this.images, {
    this.videoPaths = const [],
    this.pdfPaths = const [],
  });
}

// Shared input decoration used by both create and edit dialogs.
InputDecoration _fieldDecoration(
  String label, {
  String? hint,
  bool alignLabel = false,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  alignLabelWithHint: alignLabel,
  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.22)),
  filled: true,
  fillColor: const Color(0xFF1A2530),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Colors.blueGrey, width: 1.5),
  ),
);

Future<CreateNoteResult?> showCreateNoteDialog(BuildContext context) {
  return showDialog<CreateNoteResult>(
    context: context,
    builder: (ctx) => const _CreateNoteDialog(),
  );
}

class _CreateNoteDialog extends StatefulWidget {
  const _CreateNoteDialog();

  @override
  State<_CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<_CreateNoteDialog> {
  final _titleCtl = TextEditingController();
  final _bodyCtl = TextEditingController();

  int _selectedColor = 0;
  bool _mediaOpen = false;
  bool _canCreate = false;

  List<ImageToAttach> _pickedImages = [];
  List<String> _pickedVideos = [];
  List<String> _pickedPdfs = [];

  @override
  void initState() {
    super.initState();
    _titleCtl.addListener(_onTextChanged);
    _bodyCtl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _bodyCtl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasContent =
        _titleCtl.text.trim().isNotEmpty || _bodyCtl.text.trim().isNotEmpty;
    if (hasContent != _canCreate) setState(() => _canCreate = hasContent);
  }

  Future<void> _pickImages() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    final next = <ImageToAttach>[];
    for (final f in res.files) {
      final Uint8List? bytes =
          f.bytes ??
          (f.path != null ? await File(f.path!).readAsBytes() : null);
      if (bytes == null) continue;
      final ext = p.extension(f.name).isNotEmpty ? p.extension(f.name) : '.jpg';
      next.add(ImageToAttach(bytes, ext));
    }
    if (next.isEmpty) return;
    setState(() => _pickedImages = [..._pickedImages, ...next]);
  }

  Future<void> _pickVideos() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
      withData: false,
    );
    if (res == null || res.files.isEmpty) return;
    final next = res.files
        .map((f) => f.path ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (next.isEmpty) return;
    setState(() => _pickedVideos = [..._pickedVideos, ...next]);
  }

  Future<void> _pickPdfs() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withData: false,
    );
    if (res == null || res.files.isEmpty) return;
    final next = res.files
        .map((f) => f.path ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (next.isEmpty) return;
    setState(() => _pickedPdfs = [..._pickedPdfs, ...next]);
  }

  void _submit() {
    if (!_canCreate) return;
    Navigator.pop(
      context,
      CreateNoteResult(
        _titleCtl.text.trim(),
        _bodyCtl.text,
        kNoteColors[_selectedColor].value,
        _pickedImages,
        videoPaths: _pickedVideos,
        pdfPaths: _pickedPdfs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = (MediaQuery.of(context).size.width * 0.92).clamp(
      320.0,
      680.0,
    );

    return AlertDialog(
      backgroundColor: const Color(0xFF263238),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      title: const Text(
        'New note',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Title field ----
              TextField(
                controller: _titleCtl,
                autofocus: false,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _fieldDecoration('Title', hint: 'Enter a title..'),
              ),
              const SizedBox(height: 10),

              // ---- Body field ----
              TextField(
                controller: _bodyCtl,
                minLines: 3,
                maxLines: 8,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _fieldDecoration(
                  'Note',
                  hint: 'Enter your note..',
                  alignLabel: true,
                ),
              ),
              const SizedBox(height: 16),

              // ---- Color picker ----
              SectionLabel('Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < kNoteColors.length; i++)
                    NoteColorSwatch(
                      color: kNoteColors[i],
                      selected: _selectedColor == i,
                      onTap: () => setState(() => _selectedColor = i),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Media toggle ----
              OutlinedButton.icon(
                onPressed: () => setState(() => _mediaOpen = !_mediaOpen),
                icon: Icon(
                  _mediaOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.attach_file_rounded,
                  size: 15,
                ),
                label: Text(_mediaOpen ? 'Hide attachments' : 'Attachments'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.55),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),

              // ---- Media section ----
              if (_mediaOpen) ...[
                const SizedBox(height: 14),
                MediaSection(
                  label: 'Bilder',
                  icon: Icons.add_photo_alternate_outlined,
                  onAdd: _pickImages,
                  child: _pickedImages.isEmpty
                      ? const SizedBox.shrink()
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_pickedImages.length, (i) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _pickedImages[i].bytes,
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: RemoveBadge(
                                    onTap: () => setState(() {
                                      _pickedImages = [
                                        for (
                                          int j = 0;
                                          j < _pickedImages.length;
                                          j++
                                        )
                                          if (j != i) _pickedImages[j],
                                      ];
                                    }),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                ),
                const SizedBox(height: 12),
                MediaSection(
                  label: 'Video',
                  icon: Icons.video_collection_outlined,
                  onAdd: _pickVideos,
                  child: _pickedVideos.isEmpty
                      ? const SizedBox.shrink()
                      : ChipList(
                          items: _pickedVideos,
                          onRemove: (i) => setState(() {
                            _pickedVideos = [
                              for (int j = 0; j < _pickedVideos.length; j++)
                                if (j != i) _pickedVideos[j],
                            ];
                          }),
                        ),
                ),
                const SizedBox(height: 12),
                MediaSection(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  onAdd: _pickPdfs,
                  child: _pickedPdfs.isEmpty
                      ? const SizedBox.shrink()
                      : ChipList(
                          items: _pickedPdfs,
                          onRemove: (i) => setState(() {
                            _pickedPdfs = [
                              for (int j = 0; j < _pickedPdfs.length; j++)
                                if (j != i) _pickedPdfs[j],
                            ];
                          }),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.38),
              ),
              child: const Text('Cancel'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _canCreate ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF546E7A),
                disabledBackgroundColor: const Color(
                  0xFF546E7A,
                ).withValues(alpha: 0.25),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Create',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
