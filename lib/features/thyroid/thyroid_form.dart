import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../database/schema.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../attachments/attachments_section.dart';
import '../state/app_state.dart';

class ThyroidFormScreen extends StatefulWidget {
  const ThyroidFormScreen({super.key, this.entry});
  final ThyroidEntry? entry;

  @override
  State<ThyroidFormScreen> createState() => _ThyroidFormScreenState();
}

class _ThyroidFormScreenState extends State<ThyroidFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController date, tsh, ft4, ft3, dose, comment, decision;
  final PendingAttachments _pending = PendingAttachments();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    date = TextEditingController(text: formatDate(e?.date ?? DateTime.now()));
    tsh = TextEditingController(text: formatNum(e?.tsh));
    ft4 = TextEditingController(text: formatNum(e?.ft4));
    ft3 = TextEditingController(text: formatNum(e?.ft3));
    dose = TextEditingController(text: formatNum(e?.doseUg));
    comment = TextEditingController(text: e?.comment ?? '');
    decision = TextEditingController(text: e?.decision ?? '');
  }

  @override
  void dispose() {
    for (final c in [date, tsh, ft4, ft3, dose, comment, decision]) {
      c.dispose();
    }
    if (!_saved) _pending.discard();
    _pending.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final st = context.read<AppState>();
    final s = st.s;
    if (!_key.currentState!.validate()) return;
    final values = [tsh, ft4, ft3, dose].map((c) => parseNumber(c.text));
    if (values.every((v) => v == null)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.t('err_no_values'))));
      return;
    }
    final old = widget.entry;
    final entry = ThyroidEntry(
      id: old?.id,
      date: parseDate(date.text)!,
      tsh: parseNumber(tsh.text),
      ft4: parseNumber(ft4.text),
      ft3: parseNumber(ft3.text),
      doseUg: parseNumber(dose.text),
      comment: comment.text.trim(),
      decision: decision.text.trim(),
      source: old == null ? kSrcManual : markEdited(old.source),
    );
    final id = await st.save(thyroidT, entry);
    await st.attachPending(kAttThyroid, id, _pending.paths);
    _saved = true;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    final r = st.refs;
    return FormPage(
      title: s.t(widget.entry == null ? 'new_entry' : 'edit_entry'),
      formKey: _key,
      onSave: _save,
      saveLabel: s.t('save'),
      children: [
        DateField(controller: date, label: s.t('date'), s: s),
        numField(s, tsh, 'TSH', suffix: r.tshUnit),
        numField(s, ft4, 'FT4', suffix: r.ft4Unit),
        numField(s, ft3, 'FT3', suffix: r.ft3Unit),
        numField(s, dose, s.t('dose_ug'), suffix: 'µg'),
        textField(comment, s.t('comment'), maxLines: 2),
        textField(decision, s.t('decision'), maxLines: 2),
        AttachmentsSection(
            kind: kAttThyroid, refId: widget.entry?.id, pending: _pending),
      ],
    );
  }
}
