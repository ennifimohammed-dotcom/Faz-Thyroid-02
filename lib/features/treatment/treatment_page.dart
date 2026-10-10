import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/palette.dart';
import '../../core/format.dart';
import '../../database/schema.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../state/app_state.dart';

Color kindColor(String kind) {
  switch (kind) {
    case kDosePrescribed:
      return kRose;
    case kDoseTaken:
      return kMint;
    default:
      return kSky;
  }
}

class TreatmentPage extends StatelessWidget {
  const TreatmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    final items = st.doseItems;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: s.t('dose_history'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final k in kDoseKinds)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: kindColor(k), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.t('dose_kind_$k'))),
                  ]),
                ),
              const SizedBox(height: 6),
              Text(s.t('dose_info'),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        ColorLegend(s: s),
        if (items.isEmpty) Center(child: Text(s.t('no_data'))),
        for (var i = 0; i < items.length; i++)
          _DoseRow(item: items[i], last: i == items.length - 1),
      ],
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({required this.item, required this.last});
  final DoseItem item;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final st = context.read<AppState>();
    final s = st.s;
    final color = kindColor(item.kind);
    final ev = item.event;
    return InkWell(
      onTap: ev == null
          ? null
          : () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => DoseFormScreen(event: ev))),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 24,
              child: Column(children: [
                Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                if (!last)
                  Expanded(child: Container(width: 2, color: Colors.grey.shade400)),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${formatNum(item.doseUg)} µg',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                    Text(s.t('dose_kind_${item.kind}')),
                    Text(item.date == null
                        ? s.t('date_unknown')
                        : formatDate(item.date!)),
                    if (item.tsh != null || item.ft4 != null || item.ft3 != null) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (item.tsh != null)
                            ValueChip(
                                label: 'TSH',
                                value: item.tsh,
                                min: st.refs.tshMin,
                                max: st.refs.tshMax),
                          if (item.ft4 != null)
                            ValueChip(
                                label: 'FT4',
                                value: item.ft4,
                                min: st.refs.ft4Min,
                                max: st.refs.ft4Max),
                          if (item.ft3 != null)
                            ValueChip(
                                label: 'FT3',
                                value: item.ft3,
                                min: st.refs.ft3Min,
                                max: st.refs.ft3Max),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (item.note.isNotEmpty) Text(item.note),
                    Text('${s.t('source')} : ${sourceLabel(s, item.source)}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            if (ev != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: s.t('delete'),
                onPressed: () async {
                  if (ev.id == null) return;
                  final ok = await confirmDialog(context, s, s.t('delete_confirm'));
                  if (ok) await st.remove(doseT, ev.id!);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class DoseFormScreen extends StatefulWidget {
  const DoseFormScreen({super.key, this.event});
  final DoseEvent? event;

  @override
  State<DoseFormScreen> createState() => _DoseFormScreenState();
}

class _DoseFormScreenState extends State<DoseFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController date, dose, note;
  late String kind;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    date = TextEditingController(
        text: e == null ? formatDate(DateTime.now()) : (e.date == null ? '' : formatDate(e.date!)));
    dose = TextEditingController(text: formatNum(e?.doseUg));
    note = TextEditingController(text: e?.note ?? '');
    kind = e?.kind ?? kDosePrescribed;
  }

  @override
  void dispose() {
    date.dispose();
    dose.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final st = context.read<AppState>();
    if (!_key.currentState!.validate()) return;
    final d = parseNumber(dose.text);
    if (d == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(st.s.t('err_required'))));
      return;
    }
    final old = widget.event;
    await st.save(
      doseT,
      DoseEvent(
        id: old?.id,
        date: date.text.trim().isEmpty ? null : parseDate(date.text),
        kind: kind,
        doseUg: d,
        note: note.text.trim(),
        source: old == null ? kSrcManual : markEdited(old.source),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    return FormPage(
      title: s.t('add_dose'),
      formKey: _key,
      onSave: _save,
      saveLabel: s.t('save'),
      children: [
        DropdownButtonFormField<String>(
          initialValue: kind,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: s.t('kind'),),
          items: [
            for (final k in kDoseKinds)
              DropdownMenuItem(value: k, child: Text(s.t('dose_kind_$k'))),
          ],
          onChanged: (v) => setState(() => kind = v ?? kind),
        ),
        DateField(controller: date, label: s.t('date'), s: s, required: false),
        numField(s, dose, s.t('dose_ug'), suffix: 'µg'),
        textField(note, s.t('note'), maxLines: 2),
      ],
    );
  }
}
