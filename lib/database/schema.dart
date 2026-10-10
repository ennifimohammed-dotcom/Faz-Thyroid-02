import '../models/models.dart';

/// Description generique d'une table : nom + conversions.
class TableDef<T> {
  const TableDef(this.name, this.fromMap, this.toMap);
  final String name;
  final T Function(Map<String, Object?>) fromMap;
  final Map<String, Object?> Function(T) toMap;
}

final thyroidT = TableDef<ThyroidEntry>(
    'thyroid_entries', ThyroidEntry.fromMap, (e) => e.toMap());
final otherT = TableDef<OtherAnalysis>(
    'other_analyses', OtherAnalysis.fromMap, (e) => e.toMap());
final consultT = TableDef<Consultation>(
    'consultations', Consultation.fromMap, (e) => e.toMap());
final doseT =
    TableDef<DoseEvent>('dose_events', DoseEvent.fromMap, (e) => e.toMap());
final symptomT =
    TableDef<SymptomLog>('symptoms', SymptomLog.fromMap, (e) => e.toMap());

final attachmentT = TableDef<Attachment>(
    'attachments', Attachment.fromMap, (e) => e.toMap());

const kTableNames = [
  'thyroid_entries',
  'other_analyses',
  'consultations',
  'dose_events',
  'symptoms',
  'attachments',
];

const kAttachmentsSql = '''CREATE TABLE attachments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    kind TEXT NOT NULL,
    ref_id INTEGER NOT NULL,
    path TEXT NOT NULL,
    added_at TEXT)''';

const kSchemaSql = [
  kAttachmentsSql,
  '''CREATE TABLE thyroid_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    tsh REAL, ft4 REAL, ft3 REAL, dose_ug REAL,
    comment TEXT, decision TEXT, source TEXT)''',
  '''CREATE TABLE other_analyses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    name TEXT NOT NULL,
    value REAL, unit TEXT, ref_min REAL, ref_max REAL,
    lab TEXT, comment TEXT, source TEXT)''',
  '''CREATE TABLE consultations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    specialty TEXT, doctor TEXT, reason TEXT, diagnosis TEXT,
    decision TEXT, treatment TEXT, dose_ug REAL,
    next_control TEXT, notes TEXT, source TEXT)''',
  '''CREATE TABLE dose_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT,
    kind TEXT NOT NULL,
    dose_ug REAL NOT NULL,
    note TEXT, source TEXT)''',
  '''CREATE TABLE symptoms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    name TEXT NOT NULL,
    severity INTEGER NOT NULL,
    note TEXT)''',
];
