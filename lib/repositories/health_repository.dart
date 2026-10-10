import '../database/schema.dart';
import '../data/seed_data.dart';

typedef RawTables = Map<String, List<Map<String, Object?>>>;

/// Acces aux donnees : l'interface ne connait pas SQLite.
abstract class HealthRepository {
  Future<List<T>> all<T>(TableDef<T> t);
  Future<int> save<T>(TableDef<T> t, T item);
  Future<void> delete<T>(TableDef<T> t, int id);
  Future<RawTables> dumpRaw();

  /// Remplace tout le contenu par [data].
  Future<void> replaceAll(RawTables data);
}

/// Depot en memoire (utilise par les tests ; peut aussi servir de secours).
class MemoryRepository implements HealthRepository {
  MemoryRepository();

  factory MemoryRepository.seeded() {
    final r = MemoryRepository();
    r._tables[thyroidT.name] = [for (final e in seedThyroid) _withId(r, e.toMap())];
    r._tables[otherT.name] = [for (final e in seedOthers) _withId(r, e.toMap())];
    r._tables[doseT.name] = [for (final e in seedDoseEvents) _withId(r, e.toMap())];
    return r;
  }

  static Map<String, Object?> _withId(MemoryRepository r, Map<String, Object?> m) {
    final copy = Map<String, Object?>.from(m);
    copy['id'] = r._nextId++;
    return copy;
  }

  final Map<String, List<Map<String, Object?>>> _tables = {
    for (final n in kTableNames) n: <Map<String, Object?>>[],
  };
  int _nextId = 1;

  @override
  Future<List<T>> all<T>(TableDef<T> t) async =>
      [for (final m in _tables[t.name]!) t.fromMap(Map<String, Object?>.from(m))];

  @override
  Future<int> save<T>(TableDef<T> t, T item) async {
    final m = Map<String, Object?>.from(t.toMap(item));
    final rows = _tables[t.name]!;
    final id = m['id'] as int?;
    if (id == null) {
      m['id'] = _nextId++;
      rows.add(m);
      return m['id'] as int;
    }
    final i = rows.indexWhere((r) => r['id'] == id);
    if (i >= 0) {
      rows[i] = m;
    } else {
      rows.add(m);
    }
    return id;
  }

  @override
  Future<void> delete<T>(TableDef<T> t, int id) async =>
      _tables[t.name]!.removeWhere((r) => r['id'] == id);

  @override
  Future<RawTables> dumpRaw() async => {
        for (final e in _tables.entries)
          e.key: [for (final m in e.value) Map<String, Object?>.from(m)],
      };

  @override
  Future<void> replaceAll(RawTables data) async {
    var maxId = 0;
    for (final n in kTableNames) {
      final rows = [for (final m in data[n] ?? const <Map<String, Object?>>[]) Map<String, Object?>.from(m)];
      for (final r in rows) {
        final id = r['id'];
        if (id is int && id > maxId) maxId = id;
      }
      _tables[n] = rows;
    }
    _nextId = maxId + 1;
  }
}
