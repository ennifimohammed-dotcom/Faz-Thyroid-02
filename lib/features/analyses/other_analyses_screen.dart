import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/medical.dart';
import '../../database/schema.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../attachments/attachments_section.dart';
import '../state/app_state.dart';

const _suggestions = [
  'Anticorps ATPO', 'Anticorps ATG', 'ACTH', 'Cortisol 8H', 'Sodium', 'Potassium', 'Vitamine D', 'Ferritine',
  'Fer', 'B12', 'NFS', 'Glycémie', 'HbA1c', 'Cholestérol',
];

class OtherAnalysesScreen extends StatelessWidget {
  const OtherAnalysesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    final items = st.others;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('menu_other'))),
      floatingActionButton: FloatingActionButton(
        tooltip: s.t('add'),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OtherAnalysisForm())),
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? Center(child: Text(s.t('no_data')))
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              children: [
                for (final a in items)
                  SectionCard(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => OtherAnalysisForm(analysis: a))),
                    child: _tile(context, st, a),
                  ),
              ],
            ),
    );
  }

  Widget _tile(BuildContext context, AppState st, OtherAnalysis a) {
    final s = st.s;
    final status = statusOf(a.value, a.refMin, a.refMax);
    final color = levelColor(levelOf(a.value, a.refMin, a.refMax));
    final ref = (a.refMin == null && a.refMax == null)
        ? s.t('not_set')
        : '${formatNum(a.refMin, na: '…')} – ${formatNum(a.refMax, na: '…')} ${a.unit}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text(a.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          AttachmentBadge(count: st.attachmentCount(kAttOther, a.id)),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: s.t('delete'),
            onPressed: () async {
              if (a.id == null) return;
              final ok = await confirmDialog(context, s, s.t('delete_confirm'));
              if (ok) await st.remove(otherT, a.id!);
            },
          ),
        ]),
        Row(children: [
          Text(
              a.value == null
                  ? s.t('not_available')
                  : '${formatNum(a.value)} ${a.unit}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 10),
          Text(statusLabel(s, status),
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]),
        Text('${formatDate(a.date)} · ${s.t('ref')} : $ref',
            style: Theme.of(context).textTheme.bodySmall),
        if (a.lab.isNotEmpty) Text('${s.t('lab')} : ${a.lab}'),
        if (a.comment.isNotEmpty) Text(a.comment),
        Text('${s.t('source')} : ${sourceLabel(s, a.source)}',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class OtherAnalysisForm extends StatefulWidget {
  const OtherAnalysisForm({super.key, this.analysis});
  final OtherAnalysis? analysis;

  @override
  State<OtherAnalysisForm> createState() => _OtherAnalysisFormState();
}

class _OtherAnalysisFormState extends State<OtherAnalysisForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController name, date, value, unit, rmin, rmax, lab, comment;
  final PendingAttachments _pending = PendingAttachments();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final a = widget.analysis;
    name = TextEditingController(text: a?.name ?? '');
    date = TextEditingController(text: formatDate(a?.date ?? DateTime.now()));
    value = TextEditingController(text: formatNum(a?.value));
    unit = TextEditingController(text: a?.unit ?? '');
    rmin = TextEditingController(text: formatNum(a?.refMin));
    rmax = TextEditingController(text: formatNum(a?.refMax));
    lab = TextEditingController(text: a?.lab ?? '');
    comment = TextEditingController(text: a?.comment ?? '');
  }

  @override
  void dispose() {
    for (final c in [name, date, value, unit, rmin, rmax, lab, comment]) {
      c.dispose();
    }
    if (!_saved) _pending.discard();
    _pending.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final st = context.read<AppState>();
    final old = widget.analysis;
    final id = await st.save(
      otherT,
      OtherAnalysis(
        id: old?.id,
        date: parseDate(date.text)!,
        name: name.text.trim(),
        value: parseNumber(value.text),
        unit: unit.text.trim(),
        refMin: parseNumber(rmin.text),
        refMax: parseNumber(rmax.text),
        lab: lab.text.trim(),
        comment: comment.text.trim(),
        source: old == null ? kSrcManual : markEdited(old.source),
      ),
    );
    await st.attachPending(kAttOther, id, _pending.paths);
    _saved = true;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    return FormPage(
      title: s.t(widget.analysis == null ? 'new_analysis' : 'edit_analysis'),
      formKey: _key,
      onSave: _save,
      saveLabel: s.t('save'),
      children: [
        textField(name, s.t('analysis_name'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? s.t('err_required') : null),
        Wrap(
          spacing: 6,
          runSpacing: 0,
          children: [
            for (final sug in _suggestions)
              ActionChip(label: Text(sug), onPressed: () => name.text = sug),
          ],
        ),
        DateField(controller: date, label: s.t('date'), s: s),
        numField(s, value, s.t('value')),
        textField(unit, s.t('unit')),
        numField(s, rmin, s.t('ref_min')),
        numField(s, rmax, s.t('ref_max')),
        textField(lab, s.t('lab')),
        textField(comment, s.t('comment'), maxLines: 2),
        AttachmentsSection(
            kind: kAttOther, refId: widget.analysis?.id, pending: _pending),
      ],
    );
  }
}
