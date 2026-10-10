import 'dart:convert';

import '../database/schema.dart';
import '../repositories/health_repository.dart';

const kBackupFormat = 'thyroid_tracker_backup';
const kBackupVersion = 1;

class BackupBundle {
  BackupBundle(this.profile, this.refs, this.tables);
  final Map<String, Object?> profile;
  final Map<String, Object?> refs;
  final RawTables tables;

  int get totalRows => tables.values.fold(0, (a, b) => a + b.length);
}

String encodeBackup({
  required Map<String, Object?> profile,
  required Map<String, Object?> refs,
  required RawTables tables,
  DateTime? now,
}) {
  return const JsonEncoder.withIndent('  ').convert({
    'format': kBackupFormat,
    'version': kBackupVersion,
    'exportedAt': (now ?? DateTime.now()).toIso8601String(),
    'profile': profile,
    'refs': refs,
    'tables': tables,
  });
}

/// Lit une sauvegarde ; leve FormatException si le fichier est invalide.
BackupBundle decodeBackup(String json) {
  final Object? root;
  try {
    root = jsonDecode(json);
  } on FormatException {
    throw const FormatException('JSON invalide');
  }
  if (root is! Map || root['format'] != kBackupFormat) {
    throw const FormatException('Fichier de sauvegarde non reconnu');
  }
  final version = root['version'];
  if (version is! int || version > kBackupVersion) {
    throw const FormatException('Version de sauvegarde non supportée');
  }
  final tablesRaw = root['tables'];
  if (tablesRaw is! Map) throw const FormatException('Tables manquantes');
  final tables = <String, List<Map<String, Object?>>>{};
  for (final n in kTableNames) {
    final rows = tablesRaw[n];
    if (rows == null) {
      tables[n] = [];
      continue;
    }
    if (rows is! List) throw FormatException('Table invalide : $n');
    tables[n] = [
      for (final r in rows)
        if (r is Map) Map<String, Object?>.from(r) else throw FormatException('Ligne invalide : $n'),
    ];
  }
  Map<String, Object?> obj(Object? o) =>
      o is Map ? Map<String, Object?>.from(o) : <String, Object?>{};
  return BackupBundle(obj(root['profile']), obj(root['refs']), tables);
}
