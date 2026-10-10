import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../database/schema.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../state/app_state.dart';

class ConsultationsPage extends StatelessWidget {
  const ConsultationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    final items = st.consultations;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(s.t('decision_note'), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        if (items.isEmpty) Center(child: Text(s.t('no_data'))),
        for (final c in items)
          SectionCard(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ConsultationFormScreen(consultation: c))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(formatDate(c.date),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16))),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: s.t('delete'),
                    onPressed: () async {
                      if (c.id == null) return;
                      final ok = await confirmDialog(context, s, s.t('delete_confirm'));
                      if (ok) await st.remove(consultT, c.id!);
                    },
                  ),
                ]),
                if (c.specialty.isNotEmpty) LabeledLine(s.t('specialty'), c.specialty),
                if (c.doctor.isNotEmpty) LabeledLine(s.t('doctor'), c.doctor),
                if (c.reason.isNotEmpty) LabeledLine(s.t('reason'), c.reason),
                if (c.diagnosis.isNotEmpty) LabeledLine(s.t('diagnosis'), c.diagnosis),
                if (c.decision.isNotEmpty)
                  LabeledLine(s.t('medical_decision'), c.decision),
                if (c.treatment.isNotEmpty) LabeledLine(s.t('treatment'), c.treatment),
                if (c.doseUg != null)
                  LabeledLine(s.t('dose_short'), '${formatNum(c.doseUg)} µg'),
                if (c.nextControl != null)
                  LabeledLine(s.t('next_control'), formatDate(c.nextControl!)),
                if (c.notes.isNotEmpty) LabeledLine(s.t('notes'), c.notes),
                Text('${s.t('source')} : ${sourceLabel(s, c.source)}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}

class ConsultationFormScreen extends StatefulWidget {
  const ConsultationFormScreen({super.key, this.consultation});
  final Consultation? consultation;

  @override
  State<ConsultationFormScreen> createState() => _ConsultationFormScreenState();
}

class _ConsultationFormScreenState extends State<ConsultationFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController date, specialty, doctor, reason, diagnosis,
      decision, treatment, dose, next, notes;

  @override
  void initState() {
    super.initState();
    final c = widget.consultation;
    date = TextEditingController(text: formatDate(c?.date ?? DateTime.now()));
    specialty = TextEditingController(text: c?.specialty ?? '');
    doctor = TextEditingController(text: c?.doctor ?? '');
    reason = TextEditingController(text: c?.reason ?? '');
    diagnosis = TextEditingController(text: c?.diagnosis ?? '');
    decision = TextEditingController(text: c?.decision ?? '');
    treatment = TextEditingController(text: c?.treatment ?? '');
    dose = TextEditingController(text: formatNum(c?.doseUg));
    next = TextEditingController(
        text: c?.nextControl == null ? '' : formatDate(c!.nextControl!));
    notes = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [date, specialty, doctor, reason, diagnosis, decision,
        treatment, dose, next, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final st = context.read<AppState>();
    final old = widget.consultation;
    await st.save(
      consultT,
      Consultation(
        id: old?.id,
        date: parseDate(date.text)!,
        specialty: specialty.text.trim(),
        doctor: doctor.text.trim(),
        reason: reason.text.trim(),
        diagnosis: diagnosis.text.trim(),
        decision: decision.text.trim(),
        treatment: treatment.text.trim(),
        doseUg: parseNumber(dose.text),
        nextControl: next.text.trim().isEmpty ? null : parseDate(next.text),
        notes: notes.text.trim(),
        source: old == null ? kSrcManual : markEdited(old.source),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    return FormPage(
      title: s.t(widget.consultation == null ? 'new_consult' : 'edit_consult'),
      formKey: _key,
      onSave: _save,
      saveLabel: s.t('save'),
      children: [
        DateField(controller: date, label: s.t('date'), s: s),
        textField(specialty, s.t('specialty')),
        textField(doctor, s.t('doctor')),
        textField(reason, s.t('reason'), maxLines: 2),
        textField(diagnosis, s.t('diagnosis'), maxLines: 2),
        textField(decision, s.t('medical_decision'), maxLines: 3),
        textField(treatment, s.t('treatment'), maxLines: 2),
        numField(s, dose, s.t('dose_ug'), suffix: 'µg'),
        DateField(controller: next, label: s.t('next_control'), s: s, required: false),
        textField(notes, s.t('notes'), maxLines: 3),
      ],
    );
  }
}
