import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/palette.dart';
import '../../services/export_service.dart';
import '../../services/file_saver.dart';
import '../../services/xlsx_writer.dart';
import '../../widgets/common.dart';
import '../state/app_state.dart';

/// Export Excel complet + copie de l'historique en texte.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool busy = false;
  String? savedName;
  String? savedUri;

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _export() async {
    final st = context.read<AppState>();
    final s = st.s;
    setState(() => busy = true);
    try {
      final now = DateTime.now();
      final bytes = buildXlsx(buildExportSheets(st, now: now));
      final name = exportFileName(now);
      final uri = await FileSaver.saveToDownloads(name, bytes);
      if (!mounted) return;
      setState(() {
        savedName = name;
        savedUri = uri;
      });
    } on PlatformException catch (e) {
      _msg(e.code == 'UNSUPPORTED'
          ? s.t('export_unavailable')
          : '${s.t('export_error')} : ${e.message ?? e.code}');
    } on MissingPluginException {
      _msg(s.t('export_unavailable'));
    } catch (e) {
      _msg('${s.t('export_error')} : $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _share() async {
    final st = context.read<AppState>();
    final uri = savedUri;
    if (uri == null) return;
    try {
      await FileSaver.share(uri);
    } catch (e) {
      _msg('${st.s.t('export_error')} : $e');
    }
  }

  Future<void> _copyText() async {
    final st = context.read<AppState>();
    await Clipboard.setData(ClipboardData(text: buildHistoryText(st)));
    _msg(st.s.t('export_copied'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('menu_export'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            icon: Icons.table_view_rounded,
            title: s.t('menu_export'),
            child: Text(s.t('export_info')),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: busy ? null : _export,
            icon: const Icon(Icons.file_download_rounded),
            label: Text(s.t('export_button')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: busy ? null : _copyText,
            icon: const Icon(Icons.copy_rounded),
            label: Text(s.t('export_copy')),
          ),
          if (busy)
            const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: CircularProgressIndicator())),
          if (savedName != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              icon: Icons.check_circle_rounded,
              title: s.t('export_saved'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(savedName!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: kRoseDeep)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share_rounded),
                    label: Text(s.t('export_share')),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
