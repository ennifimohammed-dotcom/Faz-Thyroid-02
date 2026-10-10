import 'package:flutter_test/flutter_test.dart';
import 'package:fatma_zahra_thyroid_tracker/data/seed_data.dart';
import 'package:fatma_zahra_thyroid_tracker/database/schema.dart';
import 'package:fatma_zahra_thyroid_tracker/models/models.dart';
import 'package:fatma_zahra_thyroid_tracker/repositories/health_repository.dart';
import 'package:fatma_zahra_thyroid_tracker/services/backup_service.dart';

void main() {
  test('import Excel : valeurs exactes préservées', () {
    expect(seedThyroid.length, 10);
    final last = seedThyroid.last;
    expect(last.date, DateTime(2026, 9, 28));
    expect(last.tsh, 11.93);
    expect(last.ft4, 14.17);
    expect(last.ft3, 3.4);
    expect(last.doseUg, 75);
    expect(seedThyroid.first.date, DateTime(2023, 3, 9));
    expect(seedThyroid.first.tsh, 0); // valeur du fichier, conservée
    expect(seedThyroid.first.ft4, isNull); // absent, jamais 0
    expect(seedThyroid[1].ft4, 18.35);
    expect(seedThyroid[2].tsh, 13.26);
    expect(seedThyroid[5].tsh, 0.024);
    expect(seedThyroid[6].doseUg, 100);
  });

  test('autres analyses du fichier Excel', () {
    expect(seedOthers.length, 16); // 15 du fichier + cortisol fourni
    expect(seedOthers.where((e) => e.source == kSrcExcel).length, 15);
    final atpo = seedOthers.firstWhere((e) => e.name == 'Anticorps ATPO');
    expect(atpo.value, 196.59);
    expect(atpo.refMax, 50);
    final k = seedOthers.where((e) => e.name == 'Potassium').length;
    expect(k, 4);
    expect(seedDoseEvents, isEmpty);
  });

  test('sauvegarde : export puis lecture', () async {
    final repo = MemoryRepository.seeded();
    final json = encodeBackup(
      profile: const PatientProfile().toMap(),
      refs: RefRanges.defaults().toMap(),
      tables: await repo.dumpRaw(),
      now: DateTime(2026, 10, 6),
    );
    final b = decodeBackup(json);
    expect(b.tables['thyroid_entries']!.length, 10);
    expect(b.totalRows, 26);

    final other = MemoryRepository();
    await other.replaceAll(b.tables);
    final entries = await other.all(thyroidT);
    expect(entries.last.ft4, 14.17);
    expect(entries.first.ft4, isNull);
  });

  test('sauvegarde invalide refusée', () {
    expect(() => decodeBackup('pas du json'), throwsFormatException);
    expect(() => decodeBackup('{"format":"autre"}'), throwsFormatException);
  });
}
