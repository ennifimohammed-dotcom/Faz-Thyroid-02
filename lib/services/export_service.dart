import '../core/format.dart';
import '../core/medical.dart';
import '../features/state/app_state.dart';
import '../features/symptoms/symptoms_screen.dart' show symptomLabel;
import '../l10n/strings.dart';
import '../models/models.dart';
import '../widgets/common.dart' show sourceLabel, statusLabel;
import 'xlsx_writer.dart';

/// Nom du fichier : FazTyroid_AAAA-MM-JJ.xlsx
String exportFileName(DateTime now) => 'FazTyroid_${toIso(now)}.xlsx';

String _status(S s, double? v, double? min, double? max) =>
    v == null ? '' : statusLabel(s, statusOf(v, min, max));

String _range(double? min, double? max, String unit) {
  if (min == null && max == null) return '';
  return '${formatNum(min, na: '…')} – ${formatNum(max, na: '…')} $unit'.trim();
}

class _Event {
  _Event(this.date, this.order, this.type, this.detail, this.source);
  final DateTime? date;
  final int order;
  final String type, detail, source;
}

String _join(List<String> parts, [String sep = ' | ']) =>
    parts.where((p) => p.trim().isNotEmpty).join(sep);

List<_Event> _timeline(AppState st) {
  final s = st.s;
  final r = st.refs;
  final ev = <_Event>[];

  for (final e in st.thyroid) {
    final parts = <String>[
      if (e.tsh != null)
        'TSH ${formatNum(e.tsh)} ${r.tshUnit} (${_status(s, e.tsh, r.tshMin, r.tshMax)})',
      if (e.ft4 != null)
        'FT4 ${formatNum(e.ft4)} ${r.ft4Unit} (${_status(s, e.ft4, r.ft4Min, r.ft4Max)})',
      if (e.ft3 != null)
        'FT3 ${formatNum(e.ft3)} ${r.ft3Unit} (${_status(s, e.ft3, r.ft3Min, r.ft3Max)})',
      if (e.doseUg != null) '${s.t('dose_short')} ${formatNum(e.doseUg)} µg',
      if (e.comment.isNotEmpty) '${s.t('comment_short')} : ${e.comment}',
      if (e.decision.isNotEmpty) '${s.t('decision')} : ${e.decision}',
    ];
    ev.add(_Event(e.date, 0, s.t('type_bilan'), _join(parts, ' · '),
        sourceLabel(s, e.source)));
  }
  for (final d in st.doseEvents) {
    ev.add(_Event(
        d.date,
        1,
        s.t('type_dose'),
        _join(['${s.t('dose_kind_${d.kind}')} : ${formatNum(d.doseUg)} µg', d.note]),
        sourceLabel(s, d.source)));
  }
  for (final c in st.consultations) {
    ev.add(_Event(
        c.date,
        2,
        s.t('type_consult'),
        _join([
          _join([c.specialty, c.doctor], ' – '),
          if (c.reason.isNotEmpty) '${s.t('reason')} : ${c.reason}',
          if (c.diagnosis.isNotEmpty) '${s.t('diagnosis')} : ${c.diagnosis}',
          if (c.decision.isNotEmpty) '${s.t('medical_decision')} : ${c.decision}',
          if (c.treatment.isNotEmpty) '${s.t('treatment')} : ${c.treatment}',
          if (c.doseUg != null) '${s.t('dose_short')} ${formatNum(c.doseUg)} µg',
          if (c.nextControl != null)
            '${s.t('next_control')} : ${formatDate(c.nextControl!)}',
          if (c.notes.isNotEmpty) c.notes,
        ]),
        sourceLabel(s, c.source)));
  }
  for (final a in st.others) {
    ev.add(_Event(
        a.date,
        3,
        s.t('type_other'),
        _join([
          '${a.name} : ${formatNum(a.value, na: s.t('not_available'))} ${a.unit}'
              .trim(),
          if (_status(s, a.value, a.refMin, a.refMax).isNotEmpty)
            '(${_status(s, a.value, a.refMin, a.refMax)})',
          if (_range(a.refMin, a.refMax, a.unit).isNotEmpty)
            '${s.t('ref')} ${_range(a.refMin, a.refMax, a.unit)}',
          if (a.lab.isNotEmpty) '${s.t('lab')} : ${a.lab}',
          if (a.comment.isNotEmpty) a.comment,
        ], ' · '),
        sourceLabel(s, a.source)));
  }
  for (final y in st.symptoms) {
    ev.add(_Event(
        y.date,
        4,
        s.t('type_symptom'),
        _join(['${symptomLabel(s, y.name)} — ${s.t('sev_${y.severity}')} (${y.severity}/3)', y.note]),
        ''));
  }
  ev.sort((a, b) {
    if (a.date == null && b.date == null) return a.order.compareTo(b.order);
    if (a.date == null) return 1;
    if (b.date == null) return -1;
    final c = a.date!.compareTo(b.date!);
    return c != 0 ? c : a.order.compareTo(b.order);
  });
  return ev;
}

/// Historique complet en texte (copiable : une ligne par evenement).
String buildHistoryText(AppState st, {DateTime? now}) {
  final s = st.s;
  final p = st.profile;
  final name = st.lang == 'ar' ? p.nameAr : p.nameFr;
  final b = StringBuffer()
    ..writeln('${s.t('app_title')} – $name')
    ..writeln('${s.t('export_date')} : ${formatDate(now ?? DateTime.now())}')
    ..writeln()
    ..writeln('${s.t('date')}\t${s.t('timeline_type')}\t${s.t('timeline_detail')}');
  for (final e in _timeline(st)) {
    b.writeln(
        '${e.date == null ? s.t('date_unknown') : formatDate(e.date!)}\t${e.type}\t${e.detail}');
  }
  b
    ..writeln()
    ..writeln(s.t('disclaimer'));
  return b.toString();
}

List<XSheet> buildExportSheets(AppState st, {DateTime? now}) {
  final s = st.s;
  final r = st.refs;
  final p = st.profile;
  final rtl = st.lang == 'ar';
  final stamp = now ?? DateTime.now();
  final nd = s.t('not_available');
  String orNotSet(String v) => v.trim().isEmpty ? s.t('not_set') : v;
  XCell label(String t) => XCell(t, kStyleLabel);
  XCell head(String t) => XCell(t, kStyleHeader);

  // ---- Resume ---------------------------------------------------------
  final tshE = st.lastWith((e) => e.tsh);
  final ft4E = st.lastWith((e) => e.ft4);
  final ft3E = st.lastWith((e) => e.ft3);
  final doseE = st.lastWith((e) => e.doseUg);
  final presc = st.latestPrescribed;
  final next = st.nextControlDate;
  final key = readThyroid(
      tsh: tshE?.tsh, ft4: tshE?.ft4, ft3: tshE?.ft3, refs: r);

  List<Object?> stateRow(String name, double? v, String unit, double? min,
          double? max, DateTime? date) =>
      [
        label(name),
        v,
        unit,
        _range(min, max, unit),
        v == null ? nd : _status(s, v, min, max),
        date,
      ];

  final summary = <List<Object?>>[
    [XCell('${s.t('app_title')} – ${s.t('xl_summary')}', kStyleTitle)],
    [label(s.t('export_date')), stamp],
    [],
    [XCell(s.t('profile'), kStyleTitle)],
    [label(s.t('name_fr')), orNotSet(p.nameFr)],
    [label(s.t('name_ar')), orNotSet(p.nameAr)],
    [label(s.t('birth_age')), orNotSet(p.birthDate)],
    [label(s.t('sex')), s.t('female')],
    [label(s.t('weight')), orNotSet(p.weight)],
    [label(s.t('height')), orNotSet(p.height)],
    [label(s.t('diagnosis_main')), orNotSet(p.diagnosis)],
    [label(s.t('etiology')), orNotSet(p.etiology)],
    [label(s.t('pregnancy')), orNotSet(p.pregnancy)],
    [label(s.t('pregnancy_project')), orNotSet(p.pregnancyProject)],
    [],
    [XCell(s.t('current_state'), kStyleTitle)],
    [
      head(s.t('parameter')),
      head(s.t('value')),
      head(s.t('unit')),
      head(s.t('ref_band')),
      head(s.t('status')),
      head(s.t('date')),
    ],
    stateRow('TSH', tshE?.tsh, r.tshUnit, r.tshMin, r.tshMax, tshE?.date),
    stateRow('FT4', ft4E?.ft4, r.ft4Unit, r.ft4Min, r.ft4Max, ft4E?.date),
    stateRow('FT3', ft3E?.ft3, r.ft3Unit, r.ft3Min, r.ft3Max, ft3E?.date),
    [label(s.t('last_dose')), doseE?.doseUg, 'µg', '', '', doseE?.date],
    if (presc != null)
      [
        label(s.t('prescribed_dose')),
        presc.doseUg,
        'µg',
        '',
        '',
        presc.date ?? s.t('date_unknown'),
      ],
    [label(s.t('next_control')), next ?? s.t('not_set')],
    [],
    [XCell(s.t('reading'), kStyleTitle)],
    [s.t('read_${key.name}')],
    [XCell(s.t('discuss_doctor'), kStyleLabel)],
    [],
    [s.t('disclaimer')],
  ];

  // ---- Historique complet --------------------------------------------
  final timeline = <List<Object?>>[
    [s.t('date'), s.t('timeline_type'), s.t('timeline_detail'), s.t('source')],
    for (final e in _timeline(st))
      [e.date ?? s.t('date_unknown'), e.type, e.detail, e.source],
  ];

  // ---- Bilans thyroidiens ---------------------------------------------
  final thyroid = <List<Object?>>[
    [
      s.t('date'),
      'TSH (${r.tshUnit})',
      s.t('status'),
      'FT4 (${r.ft4Unit})',
      s.t('status'),
      'FT3 (${r.ft3Unit})',
      s.t('status'),
      '${s.t('dose_short')} (µg)',
      s.t('variation_tsh'),
      s.t('comment_short'),
      s.t('decision'),
      s.t('source'),
      s.t('att_count'),
    ],
  ];
  double? prevTsh;
  for (final e in st.thyroid) {
    final v = compareValues(prevTsh, e.tsh);
    thyroid.add([
      e.date,
      e.tsh,
      _status(s, e.tsh, r.tshMin, r.tshMax),
      e.ft4,
      _status(s, e.ft4, r.ft4Min, r.ft4Max),
      e.ft3,
      _status(s, e.ft3, r.ft3Min, r.ft3Max),
      e.doseUg,
      v.absolute,
      e.comment,
      e.decision,
      sourceLabel(s, e.source),
      st.attachmentCount(kAttThyroid, e.id),
    ]);
    if (e.tsh != null) prevTsh = e.tsh;
  }

  // ---- Levothyrox -----------------------------------------------------
  final levo = <List<Object?>>[
    [
      s.t('date'),
      s.t('kind'),
      '${s.t('dose_short')} (µg)',
      'TSH (${r.tshUnit})',
      s.t('note'),
      s.t('source'),
    ],
    for (final d in st.doseItems)
      [
        d.date ?? s.t('date_unknown'),
        s.t('dose_kind_${d.kind}'),
        d.doseUg,
        d.tsh,
        d.note,
        sourceLabel(s, d.source),
      ],
  ];

  // ---- Consultations --------------------------------------------------
  final consults = [...st.consultations]..sort((a, b) => a.date.compareTo(b.date));
  final consult = <List<Object?>>[
    [
      s.t('date'),
      s.t('specialty'),
      s.t('doctor'),
      s.t('reason'),
      s.t('diagnosis'),
      s.t('medical_decision'),
      s.t('treatment'),
      '${s.t('dose_short')} (µg)',
      s.t('next_control'),
      s.t('notes'),
      s.t('source'),
    ],
    for (final c in consults)
      [
        c.date,
        c.specialty,
        c.doctor,
        c.reason,
        c.diagnosis,
        c.decision,
        c.treatment,
        c.doseUg,
        c.nextControl,
        c.notes,
        sourceLabel(s, c.source),
      ],
  ];

  // ---- Autres analyses ------------------------------------------------
  final others = [...st.others]..sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
  final other = <List<Object?>>[
    [
      s.t('date'),
      s.t('analysis_name'),
      s.t('value'),
      s.t('unit'),
      s.t('ref_min'),
      s.t('ref_max'),
      s.t('status'),
      s.t('lab'),
      s.t('comment'),
      s.t('source'),
      s.t('att_count'),
    ],
    for (final a in others)
      [
        a.date,
        a.name,
        a.value,
        a.unit,
        a.refMin,
        a.refMax,
        _status(s, a.value, a.refMin, a.refMax),
        a.lab,
        a.comment,
        sourceLabel(s, a.source),
        st.attachmentCount(kAttOther, a.id),
      ],
  ];

  // ---- Symptomes ------------------------------------------------------
  final syms = [...st.symptoms]..sort((a, b) => a.date.compareTo(b.date));
  final symptoms = <List<Object?>>[
    [s.t('date'), s.t('symptom'), s.t('severity'), s.t('severity_label'), s.t('note')],
    for (final y in syms)
      [y.date, symptomLabel(s, y.name), y.severity, s.t('sev_${y.severity}'), y.note],
  ];

  // ---- Valeurs de reference ------------------------------------------
  final refs = <List<Object?>>[
    [s.t('parameter'), s.t('ref_min'), s.t('ref_max'), s.t('unit')],
    ['TSH', r.tshMin, r.tshMax, r.tshUnit],
    ['FT4', r.ft4Min, r.ft4Max, r.ft4Unit],
    ['FT3', r.ft3Min, r.ft3Max, r.ft3Unit],
  ];

  return [
    XSheet(s.t('xl_summary'), summary, widths: [30, 16, 12, 24, 18, 14], rtl: rtl),
    XSheet(s.t('xl_timeline'), timeline,
        widths: [14, 20, 90, 24], header: true, rtl: rtl),
    XSheet(s.t('xl_thyroid'), thyroid,
        widths: [14, 14, 14, 14, 14, 14, 14, 14, 18, 36, 36, 24],
        header: true,
        rtl: rtl),
    XSheet(s.t('xl_levo'), levo,
        widths: [16, 36, 14, 14, 50, 24], header: true, rtl: rtl),
    XSheet(s.t('nav_consult'), consult,
        widths: [14, 20, 20, 30, 30, 40, 30, 14, 16, 40, 24],
        header: true,
        rtl: rtl),
    XSheet(s.t('menu_other'), other,
        widths: [14, 22, 12, 12, 12, 12, 16, 18, 30, 24], header: true, rtl: rtl),
    XSheet(s.t('menu_symptoms'), symptoms,
        widths: [14, 24, 12, 16, 40], header: true, rtl: rtl),
    XSheet(s.t('ref_values'), refs, widths: [18, 14, 14, 14], header: true, rtl: rtl),
  ];
}
