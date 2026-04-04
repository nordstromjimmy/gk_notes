import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gk_notes/data/models/image_to_attach.dart';
import 'package:gk_notes/theme/note_colors.dart';
import 'package:path/path.dart' as p;

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
    final screenW = MediaQuery.of(context).size.width;
    final dialogWidth = (screenW * 0.92).clamp(360.0, 720.0);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      scrollable: true,
      title: const Text('Ny anteckning'),
      content: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            TextField(
              controller: _titleCtl,
              autofocus: true, // keyboard opens immediately
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Titel',
                hintText: 'Skriv en titel…',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Body
            TextField(
              controller: _bodyCtl,
              minLines: 3,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Text',
                hintText: 'Skriv din anteckning…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Color picker
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Färg',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < kNoteColors.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = i),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: kNoteColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: _selectedColor == i ? 2 : 1,
                          color: _selectedColor == i
                              ? Colors.black87
                              : Colors.black26,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Media toggle
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _mediaOpen = !_mediaOpen),
                icon: Icon(_mediaOpen ? Icons.expand_less : Icons.expand_more),
                label: Text(_mediaOpen ? 'Dölj bilagor' : 'Visa bilagor'),
              ),
            ),

            if (_mediaOpen) ...[
              const SizedBox(height: 8),

              // Images
              Row(
                children: [
                  Text('Bilder', style: Theme.of(context).textTheme.labelLarge),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Lägg till'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_pickedImages.length, (i) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _pickedImages[i].bytes,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: -6,
                          top: -6,
                          child: IconButton(
                            tooltip: 'Ta bort',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 28,
                              height: 28,
                            ),
                            icon: const Icon(Icons.highlight_remove, size: 18),
                            color: Colors.red,
                            onPressed: () => setState(() {
                              _pickedImages = [
                                for (int j = 0; j < _pickedImages.length; j++)
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

              const SizedBox(height: 16),

              // Videos
              Row(
                children: [
                  Text('Video', style: Theme.of(context).textTheme.labelLarge),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickVideos,
                    icon: const Icon(Icons.video_collection_outlined),
                    label: const Text('Lägg till'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (int i = 0; i < _pickedVideos.length; i++)
                    Chip(
                      label: Text(
                        p.basename(_pickedVideos[i]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => setState(() {
                        _pickedVideos = [
                          for (int j = 0; j < _pickedVideos.length; j++)
                            if (j != i) _pickedVideos[j],
                        ];
                      }),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // PDFs
              Row(
                children: [
                  Text('PDF', style: Theme.of(context).textTheme.labelLarge),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickPdfs,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Lägg till'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pickedPdfs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Chip(
                    label: Text(
                      p.basename(_pickedPdfs[i]),
                      overflow: TextOverflow.ellipsis,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => setState(() {
                      _pickedPdfs = [
                        for (int j = 0; j < _pickedPdfs.length; j++)
                          if (j != i) _pickedPdfs[j],
                      ];
                    }),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Avbryt',
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
            const Spacer(),
            FilledButton(
              // Disabled until the user has typed something.
              onPressed: _canCreate ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: _canCreate
                    ? Colors.blueGrey
                    : Colors.blueGrey.shade200,
              ),
              child: const Text('Skapa', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}
