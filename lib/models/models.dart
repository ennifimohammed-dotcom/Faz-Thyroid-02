import '../core/format.dart';

const kSrcExcel = 'excel';
const kSrcUser = 'user_provided';
const kSrcManual = 'manual';

/// Marque une donnee modifiee apres import (jamais de modification silencieuse).
String markEdited(String source) =>
    source.endsWith('+edit') ? source : '$source+edit';

String _s(Object? o) => o is String ? o : '';

int _clampSeverity(Object? o) {
  final v = o is num ? o.toInt() : 0;
  return v < 0 ? 0 : (v > 3 ? 3 : v);
}

class RefRanges {
  const RefRanges({
    this.tshMin,
    this.tshMax,
    this.ft4Min,
    this.ft4Max,
    this.ft3Min,
    this.ft3Max,
    this.tshUnit = 'mUI/L',
    this.ft4Unit = 'pmol/L',
    this.ft3Unit = 'pmol/L',
  });

  /// Valeurs de reference presentes dans le fichier Excel.
  factory RefRanges.defaults() => const RefRanges(
        tshMin: 0.27,
        tshMax: 4.2,
        ft4Min: 10.6,
        ft4Max: 19.4,
        ft3Min: 3.0,
        ft3Max: 8.5,
      );

  final double? tshMin, tshMax, ft4Min, ft4Max, ft3Min, ft3Max;
  final String tshUnit, ft4Unit, ft3Unit;

  Map<String, Object?> toMap() => {
        'tshMin': tshMin,
        'tshMax': tshMax,
        'ft4Min': ft4Min,
        'ft4Max': ft4Max,
        'ft3Min': ft3Min,
        'ft3Max': ft3Max,
        'tshUnit': tshUnit,
        'ft4Unit': ft4Unit,
        'ft3Unit': ft3Unit,
      };

  factory RefRanges.fromMap(Map<String, Object?> m) {
    final d = RefRanges.defaults();
    double? pick(String k, double? def) =>
        m.containsKey(k) ? asDouble(m[k]) : def;
    String unit(String k, String def) =>
        (m[k] is String && (m[k] as String).isNotEmpty) ? m[k] as String : def;
    return RefRanges(
      tshMin: pick('tshMin', d.tshMin),
      tshMax: pick('tshMax', d.tshMax),
      ft4Min: pick('ft4Min', d.ft4Min),
      ft4Max: pick('ft4Max', d.ft4Max),
      ft3Min: pick('ft3Min', d.ft3Min),
      ft3Max: pick('ft3Max', d.ft3Max),
      tshUnit: unit('tshUnit', d.tshUnit),
      ft4Unit: unit('ft4Unit', d.ft4Unit),
      ft3Unit: unit('ft3Unit', d.ft3Unit),
    );
  }
}

class PatientProfile {
  const PatientProfile({
    this.nameFr = 'Fatma Zahra Belqas',
    this.nameAr = 'فاطمة الزهراء بلقاس',
    this.birthDate = '',
    this.weight = '89 kg (date à confirmer / يجب تأكيد التاريخ)',
    this.height = '',
    this.diagnosis = '',
    this.etiology = '',
    this.pregnancy = '',
    this.pregnancyProject = '',
    this.nextControlWhat = '',
    this.nextControlDate,
  });

  final String nameFr,
      nameAr,
      birthDate,
      weight,
      height,
      diagnosis,
      etiology,
      pregnancy,
      pregnancyProject,
      nextControlWhat;
  final DateTime? nextControlDate;

  Map<String, Object?> toMap() => {
        'nameFr': nameFr,
        'nameAr': nameAr,
        'birthDate': birthDate,
        'weight': weight,
        'height': height,
        'diagnosis': diagnosis,
        'etiology': etiology,
        'pregnancy': pregnancy,
        'pregnancyProject': pregnancyProject,
        'nextControlWhat': nextControlWhat,
        'nextControlDate':
            nextControlDate == null ? null : toIso(nextControlDate!),
      };

  factory PatientProfile.fromMap(Map<String, Object?> m) {
    const d = PatientProfile();
    String pick(String k, String def) => m.containsKey(k) ? _s(m[k]) : def;
    return PatientProfile(
      nameFr: pick('nameFr', d.nameFr),
      nameAr: pick('nameAr', d.nameAr),
      birthDate: pick('birthDate', d.birthDate),
      weight: pick('weight', d.weight),
      height: pick('height', d.height),
      diagnosis: pick('diagnosis', d.diagnosis),
      etiology: pick('etiology', d.etiology),
      pregnancy: pick('pregnancy', d.pregnancy),
      pregnancyProject: pick('pregnancyProject', d.pregnancyProject),
      nextControlWhat: pick('nextControlWhat', d.nextControlWhat),
      nextControlDate: fromIso(m['nextControlDate']),
    );
  }
}

/// Une ligne de la feuille Suivi_TSH_T4.
class ThyroidEntry {
  ThyroidEntry({
    this.id,
    required this.date,
    this.tsh,
    this.ft4,
    this.ft3,
    this.doseUg,
    this.comment = '',
    this.decision = '',
    this.source = kSrcManual,
  });

  final int? id;
  final DateTime date;
  final double? tsh, ft4, ft3, doseUg;
  final String comment, decision, source;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': toIso(date),
        'tsh': tsh,
        'ft4': ft4,
        'ft3': ft3,
        'dose_ug': doseUg,
        'comment': comment,
        'decision': decision,
        'source': source,
      };

  factory ThyroidEntry.fromMap(Map<String, Object?> m) => ThyroidEntry(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        tsh: asDouble(m['tsh']),
        ft4: asDouble(m['ft4']),
        ft3: asDouble(m['ft3']),
        doseUg: asDouble(m['dose_ug']),
        comment: _s(m['comment']),
        decision: _s(m['decision']),
        source: _s(m['source']).isEmpty ? kSrcManual : _s(m['source']),
      );
}

/// Une ligne de la feuille Autre_Analy.
class OtherAnalysis {
  OtherAnalysis({
    this.id,
    required this.date,
    required this.name,
    this.value,
    this.unit = '',
    this.refMin,
    this.refMax,
    this.lab = '',
    this.comment = '',
    this.source = kSrcManual,
  });

  final int? id;
  final DateTime date;
  final String name, unit, lab, comment, source;
  final double? value, refMin, refMax;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': toIso(date),
        'name': name,
        'value': value,
        'unit': unit,
        'ref_min': refMin,
        'ref_max': refMax,
        'lab': lab,
        'comment': comment,
        'source': source,
      };

  factory OtherAnalysis.fromMap(Map<String, Object?> m) => OtherAnalysis(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        name: _s(m['name']),
        value: asDouble(m['value']),
        unit: _s(m['unit']),
        refMin: asDouble(m['ref_min']),
        refMax: asDouble(m['ref_max']),
        lab: _s(m['lab']),
        comment: _s(m['comment']),
        source: _s(m['source']).isEmpty ? kSrcManual : _s(m['source']),
      );
}

/// Une ligne de la feuille Consultations_Decisions (+ medecin, notes).
class Consultation {
  Consultation({
    this.id,
    required this.date,
    this.specialty = '',
    this.doctor = '',
    this.reason = '',
    this.diagnosis = '',
    this.decision = '',
    this.treatment = '',
    this.doseUg,
    this.nextControl,
    this.notes = '',
    this.source = kSrcManual,
  });

  final int? id;
  final DateTime date;
  final String specialty,
      doctor,
      reason,
      diagnosis,
      decision,
      treatment,
      notes,
      source;
  final double? doseUg;
  final DateTime? nextControl;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': toIso(date),
        'specialty': specialty,
        'doctor': doctor,
        'reason': reason,
        'diagnosis': diagnosis,
        'decision': decision,
        'treatment': treatment,
        'dose_ug': doseUg,
        'next_control': nextControl == null ? null : toIso(nextControl!),
        'notes': notes,
        'source': source,
      };

  factory Consultation.fromMap(Map<String, Object?> m) => Consultation(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        specialty: _s(m['specialty']),
        doctor: _s(m['doctor']),
        reason: _s(m['reason']),
        diagnosis: _s(m['diagnosis']),
        decision: _s(m['decision']),
        treatment: _s(m['treatment']),
        doseUg: asDouble(m['dose_ug']),
        nextControl: fromIso(m['next_control']),
        notes: _s(m['notes']),
        source: _s(m['source']).isEmpty ? kSrcManual : _s(m['source']),
      );
}

const kDoseRecorded = 'recorded';
const kDosePrescribed = 'prescribed';
const kDoseTaken = 'taken';
const kDoseKinds = [kDoseRecorded, kDosePrescribed, kDoseTaken];

/// Evenement de dose : saisie / prescrite par le medecin / reellement prise.
class DoseEvent {
  DoseEvent({
    this.id,
    this.date,
    required this.kind,
    required this.doseUg,
    this.note = '',
    this.source = kSrcManual,
  });

  final int? id;
  final DateTime? date;
  final String kind, note, source;
  final double doseUg;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date == null ? null : toIso(date!),
        'kind': kind,
        'dose_ug': doseUg,
        'note': note,
        'source': source,
      };

  factory DoseEvent.fromMap(Map<String, Object?> m) => DoseEvent(
        id: m['id'] as int?,
        date: fromIso(m['date']),
        kind: kDoseKinds.contains(m['kind']) ? m['kind'] as String : kDoseRecorded,
        doseUg: asDouble(m['dose_ug']) ?? 0,
        note: _s(m['note']),
        source: _s(m['source']).isEmpty ? kSrcManual : _s(m['source']),
      );
}

/// Entree affichee dans la timeline Levothyrox (dose + provenance).
class DoseItem {
  const DoseItem({
    required this.date,
    required this.kind,
    required this.doseUg,
    this.note = '',
    this.source = kSrcManual,
    this.event,
    this.tsh,
    this.ft4,
    this.ft3,
  });
  final DateTime? date;
  final String kind, note, source;
  final double doseUg;
  final DoseEvent? event;
  final double? tsh, ft4, ft3;
}

class SymptomLog {
  SymptomLog({
    this.id,
    required this.date,
    required this.name,
    required this.severity,
    this.note = '',
  });

  final int? id;
  final DateTime date;
  final String name, note;
  final int severity;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': toIso(date),
        'name': name,
        'severity': severity,
        'note': note,
      };

  factory SymptomLog.fromMap(Map<String, Object?> m) => SymptomLog(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        name: _s(m['name']),
        severity: _clampSeverity(m['severity']),
        note: _s(m['note']),
      );
}

class ChartPoint {
  const ChartPoint(this.date, this.value);
  final DateTime date;
  final double value;
  double get x => date.millisecondsSinceEpoch / 86400000.0;
}

const kAttThyroid = 'thyroid';
const kAttOther = 'other';

/// Photo jointe a un bilan thyroidien ou a une autre analyse.
class Attachment {
  Attachment({
    this.id,
    required this.kind,
    required this.refId,
    required this.path,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  final int? id;
  final String kind;
  final int refId;
  final String path;
  final DateTime addedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'kind': kind,
        'ref_id': refId,
        'path': path,
        'added_at': toIso(addedAt),
      };

  factory Attachment.fromMap(Map<String, Object?> m) => Attachment(
        id: m['id'] as int?,
        kind: _s(m['kind']),
        refId: (m['ref_id'] as num).toInt(),
        path: _s(m['path']),
        addedAt: fromIso(m['added_at']) ?? DateTime.now(),
      );
}
