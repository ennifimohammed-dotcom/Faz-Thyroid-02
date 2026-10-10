import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/file_saver.dart';
import '../../widgets/common.dart';
import '../state/app_state.dart';

/// Photos choisies dans un formulaire avant l'enregistrement de la ligne.
class PendingAttachments extends ChangeNotifier {
  final List<String> paths = [];

  void add(String p) {
    paths.add(p);
    notifyListeners();
  }

  Future<void> remove(String p) async {
    paths.remove(p);
    await deleteLocalFile(p);
    notifyListeners();
  }

  /// Supprime les fichiers jamais rattaches (formulaire abandonne).
  Future<void> discard() async {
    for (final p in List<String>.from(paths)) {
      await deleteLocalFile(p);
    }
    paths.clear();
  }
}

class AttachmentsSection extends StatelessWidget {
  const AttachmentsSection({
    super.key,
    required this.kind,
    required this.refId,
    required this.pending,
  });

  final String kind;
  final int? refId;
  final PendingAttachments pending;

  Future<void> _add(BuildContext context, {required bool camera}) async {
    final st = context.read<AppState>();
    final s = st.s;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path =
          camera ? await FileSaver.captureImage() : await FileSaver.pickImage();
      if (path == null) return;
      final id = refId;
      if (id != null) {
        await st.addAttachment(kind, id, path);
      } else {
        pending.add(path);
      }
    } on MissingPluginException {
      messenger.showSnackBar(SnackBar(content: Text(s.t('att_unavailable'))));
    } on PlatformException catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('${s.t('att_error')} : ${e.message ?? e.code}')));
    }
  }

  Future<void> _delete(BuildContext context, String path) async {
    final st = context.read<AppState>();
    final s = st.s;
    final ok = await confirmDialog(context, s, s.t('att_delete_confirm'));
    if (!ok) return;
    if (pending.paths.contains(path)) {
      await pending.remove(path);
      return;
    }
    for (final a in st.attachmentsFor(kind, refId)) {
      if (a.path == path) {
        await st.deleteAttachment(a);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    return AnimatedBuilder(
      animation: pending,
      builder: (ctx, _) {
        final saved = st.attachmentsFor(kind, refId);
        final all = [...saved.map((a) => a.path), ...pending.paths];
        return SectionCard(
          icon: Icons.photo_library_rounded,
          title: s.t('att_title'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.t('att_hint'), style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 10),
              if (all.isEmpty)
                Text(s.t('att_empty'))
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < all.length; i++)
                      _Thumb(
                        path: all[i],
                        onOpen: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                                builder: (_) => ImageViewerScreen(
                                    paths: all, initialIndex: i))),
                        onDelete: () => _delete(ctx, all[i]),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _add(ctx, camera: false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(s.t('att_gallery')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _add(ctx, camera: true),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(s.t('att_camera')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb(
      {required this.path, required this.onOpen, required this.onDelete});
  final String path;
  final VoidCallback onOpen, onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onOpen,
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 3,
            end: 3,
            child: GestureDetector(
              onTap: onDelete,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visionneuse plein ecran avec zoom (pincer) et defilement entre photos.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen(
      {super.key, required this.paths, this.initialIndex = 0});
  final List<String> paths;
  final int initialIndex;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.paths.length}',
            style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.paths.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 6,
          child: Center(
            child: Image.file(
              File(widget.paths[i]),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64),
            ),
          ),
        ),
      ),
    );
  }
}

/// Petit badge « trombone + nombre » pour les cartes de liste.
class AttachmentBadge extends StatelessWidget {
  const AttachmentBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.attach_file_rounded, size: 18, color: color),
        Text('$count',
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
