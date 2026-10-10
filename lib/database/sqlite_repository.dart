import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/format.dart';
import '../data/seed_data.dart';
import '../repositories/health_repository.dart';
import 'schema.dart';

class SqliteRepository implements HealthRepository {
  SqliteRepository._(this._db);
  final Database _db;

  /// Version 3 : photos jointes. Version 2 : integration de l'historique complet du fichier Excel.
  static const int _dbVersion = 3;

  static Future<SqliteRepository> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'thyroid_tracker.db'),
      version: _dbVersion,
      onCreate: (db, version) async {
        for (final sql in kSchemaSql) {
          await db.execute(sql);
        }
        await _seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Remplace uniquement les donnees initiales (source Excel / fournie
          // par l'utilisateur). Les lignes saisies ou modifiees par
          // l'utilisatrice (source « manual » ou « ...+edit ») sont conservees.
          for (final table in [thyroidT.name, otherT.name, doseT.name]) {
            await db.delete(table,
                where: "source IN ('excel', 'user_provided')");
          }
          await _seed(db);
        }
        if (oldVersion < 3) {
          await db.execute(kAttachmentsSql);
        }
      },
    );
    return SqliteRepository._(db);
  }

  /// Insere les donnees initiales sans doublonner une ligne deja presente
  /// (meme date, ou meme date + nom pour les autres analyses).
  static Future<void> _seed(DatabaseExecutor db) async {
    final thyroidDates = {
      for (final r in await db.query(thyroidT.name, columns: ['date']))
        r['date'] as String,
    };
    final otherKeys = {
      for (final r in await db.query(otherT.name, columns: ['date', 'name']))
        '${r['date']}|${r['name']}',
    };
    final batch = db.batch();
    void ins(String table, Map<String, Object?> m) {
      batch.insert(table, Map<String, Object?>.from(m)..remove('id'));
    }

    for (final e in seedThyroid) {
      if (!thyroidDates.contains(toIso(e.date))) ins(thyroidT.name, e.toMap());
    }
    for (final e in seedOthers) {
      if (!otherKeys.contains('${toIso(e.date)}|${e.name}')) {
        ins(otherT.name, e.toMap());
      }
    }
    for (final e in seedDoseEvents) {
      ins(doseT.name, e.toMap());
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<T>> all<T>(TableDef<T> t) async {
    final rows = await _db.query(t.name);
    return [for (final r in rows) t.fromMap(r)];
  }

  @override
  Future<int> save<T>(TableDef<T> t, T item) async {
    final m = Map<String, Object?>.from(t.toMap(item));
    final id = m['id'] as int?;
    if (id == null) {
      m.remove('id');
      return _db.insert(t.name, m);
    }
    await _db.insert(t.name, m, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  @override
  Future<void> delete<T>(TableDef<T> t, int id) async {
    await _db.delete(t.name, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<RawTables> dumpRaw() async {
    final out = <String, List<Map<String, Object?>>>{};
    for (final n in kTableNames) {
      final rows = await _db.query(n);
      out[n] = [for (final r in rows) Map<String, Object?>.from(r)];
    }
    return out;
  }

  @override
  Future<void> replaceAll(RawTables data) async {
    await _db.transaction((txn) async {
      for (final n in kTableNames) {
        await txn.delete(n);
        for (final row in data[n] ?? const <Map<String, Object?>>[]) {
          await txn.insert(n, row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }
}
