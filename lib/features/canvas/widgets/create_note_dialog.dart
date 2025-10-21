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
  const CreateNoteResult(
    this.title,
    this.text,
    this.colorValue,
    this.images, {
    this.videoPaths = const [],
  });
}

Future<CreateNoteResult?> showCreateNoteDialog(BuildContext context) async {
  final titleCtl = TextEditingController();
  final bodyCtl = TextEditingController();
  int selected = 0;

  // local state for picked media
  List<ImageToAttach> pickedImages = [];
  List<String> pickedVideos = [];

  final res = await showDialog<CreateNoteResult>(
    context: context,
    builder: (ctx) {
      final screenW = MediaQuery.of(ctx).size.width;
      final dialogWidth = (screenW * 0.92).clamp(360.0, 720.0);

      Future<void> pickImages(Function(void Function()) setState) async {
        final res = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          withData: true, // gives bytes even when path is null (Android SAF)
        );
        if (res == null || res.files.isEmpty) return;
        final next = <ImageToAttach>[];
        for (final f in res.files) {
          final Uint8List? bytes =
              f.bytes ??
              (f.path != null ? await File(f.path!).readAsBytes() : null);
          if (bytes == null) continue;
          final ext = p.extension(f.name).isNotEmpty
              ? p.extension(f.name)
              : '.jpg';
          next.add(ImageToAttach(bytes, ext));
        }
        setState(() => pickedImages = [...pickedImages, ...next]);
      }

      Future<void> pickVideos(Function(void Function()) setState) async {
        final res = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: true,
          withData: false, // don't pull huge video bytes into memory
        );
        if (res == null || res.files.isEmpty) return;

        final next = <String>[];
        for (final f in res.files) {
          if (f.path != null && f.path!.isNotEmpty) {
            next.add(f.path!);
          }
          // If path is null (rare with SAF for videos), we skip. Handling
          // content streams is possible but heavier—let's keep it simple.
        }
        if (next.isEmpty) return;
        setState(() => pickedVideos = [...pickedVideos, ...next]);
      }

      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
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
                  controller: titleCtl,
                  autofocus: true,
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
                  controller: bodyCtl,
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
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < kNoteColors.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => selected = i),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: kNoteColors[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: selected == i ? 2 : 1,
                              color: selected == i
                                  ? Colors.black87
                                  : Colors.black26,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Images section
                Row(
                  children: [
                    Text('Bilder', style: Theme.of(ctx).textTheme.labelLarge),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => pickImages(setState),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Lägg till'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: pickedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final img = pickedImages[i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              img.bytes,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              tooltip: 'Ta bort',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 28,
                                height: 28,
                              ),
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() {
                                pickedImages = [
                                  for (int j = 0; j < pickedImages.length; j++)
                                    if (j != i) pickedImages[j],
                                ];
                              }),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Videos section
                Row(
                  children: [
                    Text('Video', style: Theme.of(ctx).textTheme.labelLarge),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => pickVideos(setState),
                      icon: const Icon(Icons.video_collection_outlined),
                      label: const Text('Lägg till'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Show simple chips with file names; thumbnails will be generated later after note is created
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (int i = 0; i < pickedVideos.length; i++)
                        Chip(
                          label: Text(
                            p.basename(pickedVideos[i]),
                            overflow: TextOverflow.ellipsis,
                          ),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () => setState(() {
                            pickedVideos = [
                              for (int j = 0; j < pickedVideos.length; j++)
                                if (j != i) pickedVideos[j],
                            ];
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          actions: [
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Avbryt',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      ctx,
                      CreateNoteResult(
                        titleCtl.text.trim(),
                        bodyCtl.text,
                        kNoteColors[selected].value,
                        pickedImages,
                        videoPaths: pickedVideos,
                      ),
                    );
                  },
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(
                      Colors.blueGrey,
                    ),
                  ),
                  child: const Text(
                    'Skapa',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  return res;
}
