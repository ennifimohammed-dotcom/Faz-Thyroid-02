import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/palette.dart';
import '../../core/format.dart';
import '../../database/schema.dart';
import '../../l10n/strings.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../state/app_state.dart';

const kSymptomKeys = [
  'fatigue', 'somnolence', 'weight_gain', 'weight_loss', 'constipation',
  'chilliness', 'hair_loss', 'palpitations', 'tremors', 'nervousness',
  'sleep', 'irregular_periods', 'other',
];

String symptomLabel(S s, String name) =>
    kSymptomKeys.contains(name) && name != 'other' ? s.t('sym_$name') : name;

class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({super.key});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  String? selected;

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    final names = st.symptoms.map((e) => e.name).toSet().toList();
    if (selected != null && !names.contains(selected)) selected = null;
    selected ??= names.isEmpty ? null : names.first;
    final pts = selected == null
        ? <ChartPoint>[]
        : (st.symptoms.where((e) => e.name == selected).toList()
              ..sort((a, b) => a.date.compareTo(b.date)))
            .map((e) => ChartPoint(e.date, e.severity.toDouble()))
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.t('menu_symptoms'))),
      floatingActionButton: FloatingActionButton(
        tooltip: s.t('add'),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SymptomForm())),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        children: [
          Text(s.t('symptom_hint'), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          if (names.isNotEmpty)
            SectionCard(
              title: s.t('symptom_evolution'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: selected,
                    isExpanded: true,
                    items: [
                      for (final n in names)
                        DropdownMenuItem(value: n, child: Text(symptomLabel(s, n))),
                    ],
                    onChanged: (v) => setState(() => selected = v),
                  ),
                  TrendChart(
                    points: pts,
                    color: kRose,
                    emptyText: s.t('no_data'),
                    yMin: 0,
                    yMax: 3,
                    height: 160,
                  ),
                ],
              ),
            ),
          if (st.symptoms.isEmpty) Center(child: Text(s.t('no_data'))),
          for (final e in st.symptoms)
            Card(
              child: ListTile(
                title: Text('${symptomLabel(s, e.name)} — ${s.t('sev_${e.severity}')}'),
                subtitle: Text(
                    '${formatDate(e.date)}${e.note.isEmpty ? '' : '\n${e.note}'}'),
                isThreeLine: e.note.isNotEmpty,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: s.t('delete'),
                  onPressed: () async {
                    if (e.id == null) return;
                    final ok = await confirmDialog(context, s, s.t('delete_confirm'));
                    if (ok) await st.remove(symptomT, e.id!);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SymptomForm extends StatefulWidget {
  const SymptomForm({super.key});

  @override
  State<SymptomForm> createState() => _SymptomFormState();
}

class _SymptomFormState extends State<SymptomForm> {
  final _key = GlobalKey<FormState>();
  final date = TextEditingController(text: formatDate(DateTime.now()));
  final custom = TextEditingController();
  final note = TextEditingController();
  String symptom = kSymptomKeys.first;
  int severity = 1;

  @override
  void dispose() {
    date.dispose();
    custom.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final st = context.read<AppState>();
    final name = symptom == 'other' ? custom.text.trim() : symptom;
    await st.save(
      symptomT,
      SymptomLog(
          date: parseDate(date.text)!,
          name: name,
          severity: severity,
          note: note.text.trim()),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    return FormPage(
      title: s.t('new_symptom'),
      formKey: _key,
      onSave: _save,
      saveLabel: s.t('save'),
      children: [
        DateField(controller: date, label: s.t('date'), s: s),
        DropdownButtonFormField<String>(
          initialValue: symptom,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: s.t('symptom'),),
          items: [
            for (final k in kSymptomKeys)
              DropdownMenuItem(value: k, child: Text(s.t('sym_$k'))),
          ],
          onChanged: (v) => setState(() => symptom = v ?? symptom),
        ),
        if (symptom == 'other')
          textField(custom, s.t('custom_symptom'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? s.t('err_required') : null),
        Text(s.t('severity')),
        SegmentedButton<int>(
          segments: [
            for (var i = 0; i <= 3; i++)
              ButtonSegment(value: i, label: Text('$i')),
          ],
          selected: {severity},
          onSelectionChanged: (v) => setState(() => severity = v.first),
        ),
        Text(s.t('sev_$severity')),
        textField(note, s.t('note'), maxLines: 2),
      ],
    );
  }
}
