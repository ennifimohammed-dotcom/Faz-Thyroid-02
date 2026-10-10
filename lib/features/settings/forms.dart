import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../state/app_state.dart';

/// Prochain controle (ex. TSH + FT4) et date.
class NextControlScreen extends StatefulWidget {
  const NextControlScreen({super.key});

  @override
  State<NextControlScreen> createState() => _NextControlScreenState();
}

class _NextControlScreenState extends State<NextControlScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController what, date;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    what = TextEditingController(text: p.nextControlWhat);
    date = TextEditingController(
        text: p.nextControlDate == null ? '' : formatDate(p.nextControlDate!));
  }

  @override
  void dispose() {
    what.dispose();
    date.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final st = context.read<AppState>();
    final p = st.profile.toMap();
    p['nextControlWhat'] = what.text.trim();
    p['nextControlDate'] =
        date.text.trim().isEmpty ? null : toIso(parseDate(date.text)!);
    await st.setProfile(PatientProfile.fromMap(p));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    return FormPage(
      title: s.t('next_control'),
      formKey: _key,
      onSave: _save,
      saveLabel: s.t('save'),
      children: [
        textField(what, s.t('control_what')),
        DateField(controller: date, label: s.t('date'), s: s, required: false),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> c;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    c = {
      'nameFr': TextEditingController(text: p.nameFr),
      'nameAr': TextEditingController(text: p.nameAr),
      'birthDate': TextEditingController(text: p.birthDate),
      'weight': TextEditingController(text: p.weight),
      'height': TextEditingController(text: p.height),
      'diagnosis': TextEditingController(text: p.diagnosis),
      'etiology': TextEditingController(text: p.etiology),
      'pregnancy': TextEditingController(text: p.pregnancy),
      'pregnancyProject': TextEditingController(text: p.pregnancyProject),
    };
  }

  @override
  void dispose() {
    for (final x in c.values) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final st = context.read<AppState>();
    final m = st.profile.toMap();
    for (final e in c.entries) {
      m[e.key] = e.value.text.trim();
    }
    await st.setProfile(PatientProfile.fromMap(m));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    return FormPage(
      title: s.t('profile'),
      formKey: _key,
      onSave: _save,
      saveLabel: s.t('save'),
      children: [
        textField(c['nameFr']!, s.t('name_fr')),
        textField(c['nameAr']!, s.t('name_ar')),
        textField(c['birthDate']!, s.t('birth_age')),
        InputDecorator(
          decoration: InputDecoration(
              labelText: s.t('sex'),),
          child: Text(s.t('female')),
        ),
        textField(c['weight']!, s.t('weight')),
        textField(c['height']!, s.t('height')),
        textField(c['diagnosis']!, s.t('diagnosis_main')),
        textField(c['etiology']!, s.t('etiology')),
        textField(c['pregnancy']!, s.t('pregnancy')),
        textField(c['pregnancyProject']!, s.t('pregnancy_project')),
        Text(s.t('profile_hint'), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class RefsScreen extends StatefulWidget {
  const RefsScreen({super.key});

  @override
  State<RefsScreen> createState() => _RefsScreenState();
}

class _RefsScreenState extends State<RefsScreen> {
  final _key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> c;

  @override
  void initState() {
    super.initState();
    final r = context.read<AppState>().refs;
    c = {
      'tshMin': TextEditingController(text: formatNum(r.tshMin)),
      'tshMax': TextEditingController(text: formatNum(r.tshMax)),
      'ft4Min': TextEditingController(text: formatNum(r.ft4Min)),
      'ft4Max': TextEditingController(text: formatNum(r.ft4Max)),
      'ft3Min': TextEditingController(text: formatNum(r.ft3Min)),
      'ft3Max': TextEditingController(text: formatNum(r.ft3Max)),
      'tshUnit': TextEditingController(text: r.tshUnit),
      'ft4Unit': TextEditingController(text: r.ft4Unit),
      'ft3Unit': TextEditingController(text: r.ft3Unit),
    };
  }

  @override
  void dispose() {
    for (final x in c.values) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final st = context.read<AppState>();
    double? n(String k) => parseNumber(c[k]!.text);
    String u(String k, String def) =>
        c[k]!.text.trim().isEmpty ? def : c[k]!.text.trim();
    await st.setRefs(RefRanges(
      tshMin: n('tshMin'),
      tshMax: n('tshMax'),
      ft4Min: n('ft4Min'),
      ft4Max: n('ft4Max'),
      ft3Min: n('ft3Min'),
      ft3Max: n('ft3Max'),
      tshUnit: u('tshUnit', 'mUI/L'),
      ft4Unit: u('ft4Unit', 'pmol/L'),
      ft3Unit: u('ft3Unit', 'pmol/L'),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    Widget group(String name, String min, String max, String unit) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: gap([
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            numField(s, c[min]!, s.t('ref_min')),
            numField(s, c[max]!, s.t('ref_max')),
            textField(c[unit]!, s.t('unit')),
          ]),
        );
    return FormPage(
      title: s.t('ref_values'),
      formKey: _key,
      onSave: _save,
      saveLabel: s.t('save'),
      children: [
        Text(s.t('ref_note'), style: Theme.of(context).textTheme.bodySmall),
        group('TSH', 'tshMin', 'tshMax', 'tshUnit'),
        group('FT4', 'ft4Min', 'ft4Max', 'ft4Unit'),
        group('FT3', 'ft3Min', 'ft3Max', 'ft3Unit'),
      ],
    );
  }
}
