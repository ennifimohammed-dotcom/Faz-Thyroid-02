import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatma_zahra_thyroid_tracker/features/state/app_state.dart';
import 'package:fatma_zahra_thyroid_tracker/repositories/health_repository.dart';
import 'package:fatma_zahra_thyroid_tracker/services/export_service.dart';
import 'package:fatma_zahra_thyroid_tracker/services/xlsx_writer.dart';

Future<AppState> _state({String lang = 'fr'}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final st = AppState(repo: MemoryRepository.seeded(), prefs: prefs);
  await st.load();
  if (lang != 'fr') await st.setLang(lang);
  return st;
}

/// Lit les noms de fichiers du repertoire central d'un ZIP.
List<String> _zipNames(Uint8List z) {
  final bd = ByteData.sublistView(z);
  final eocd = z.length - 22;
  expect(bd.getUint32(eocd, Endian.little), 0x06054b50);
  final count = bd.getUint16(eocd + 10, Endian.little);
  var off = bd.getUint32(eocd + 16, Endian.little);
  final names = <String>[];
  for (var i = 0; i < count; i++) {
    expect(bd.getUint32(off, Endian.little), 0x02014b50);
    final n = bd.getUint16(off + 28, Endian.little);
    final extra = bd.getUint16(off + 30, Endian.little);
    final com = bd.getUint16(off + 32, Endian.little);
    names.add(utf8.decode(z.sublist(off + 46, off + 46 + n)));
    off += 46 + n + extra + com;
  }
  return names;
}

void main() {
  test('CRC32 de référence', () {
    expect(crc32(utf8.encode('123456789')), 0xCBF43926);
  });

  test('colonnes et dates Excel', () {
    expect(xlsxColumnName(0), 'A');
    expect(xlsxColumnName(25), 'Z');
    expect(xlsxColumnName(26), 'AA');
    expect(xlsxDateSerial(DateTime(2026, 9, 28)), 46293);
    expect(xlsxEscape('a&b<c>"d"'), 'a&amp;b&lt;c&gt;&quot;d&quot;');
  });

  test('classeur valide : structure ZIP et feuilles', () async {
    final st = await _state();
    final sheets = buildExportSheets(st, now: DateTime(2026, 10, 9));
    final bytes = buildXlsx(sheets);
    expect(bytes[0], 0x50); // 'P'
    expect(bytes[1], 0x4B); // 'K'
    final names = _zipNames(bytes);
    expect(names.first, '[Content_Types].xml');
    expect(names, contains('xl/workbook.xml'));
    expect(names, contains('xl/styles.xml'));
    expect(names.where((n) => n.startsWith('xl/worksheets/')).length, sheets.length);
  });

  test('toutes les données sont dans l\'export (français)', () async {
    final st = await _state();
    final sheets = {
      for (final s in buildExportSheets(st, now: DateTime(2026, 10, 9))) s.name: s,
    };
    expect(sheets.keys, containsAll(['Résumé', 'Historique complet', 'Bilans thyroïdiens', 'Levothyrox']));

    final thyroid = sheets['Bilans thyroïdiens']!;
    expect(thyroid.rows.length, 1 + 10); // en-tête + 10 bilans
    final last = thyroid.rows.last;
    expect(last[1], 11.93);
    expect(last[3], 14.17);
    expect(last[5], 3.4);
    expect(last[7], 75);
    expect(last[8], closeTo(1.03, 1e-9)); // 11.93 - 10.9
    expect(thyroid.rows[1][3], isNull); // FT4 absent : vide, jamais 0
    expect(thyroid.rows[1][1], 0); // TSH = 0 du fichier, conservé

    // historique : 10 bilans + 16 autres analyses
    expect(sheets['Historique complet']!.rows.length, 1 + 26);
    expect(sheets['Autres analyses']!.rows.length, 1 + 16);
    expect(sheets['Levothyrox']!.rows.length, 1 + 4);
  });

  test('export en arabe : feuilles RTL', () async {
    final st = await _state(lang: 'ar');
    final sheets = buildExportSheets(st, now: DateTime(2026, 10, 9));
    expect(sheets.every((s) => s.rtl), isTrue);
    expect(sheets.first.name, 'ملخص');
    expect(buildXlsx(sheets).length, greaterThan(1000));
  });

  test('historique en texte copiable', () async {
    final st = await _state();
    final text = buildHistoryText(st, now: DateTime(2026, 10, 9));
    expect(text, contains('28/09/2026'));
    expect(text, contains('TSH 11.93'));
    expect(text, contains('Anticorps ATPO'));
    expect(text, contains('09/03/2023'));
  });

  test('nom du fichier', () {
    expect(exportFileName(DateTime(2026, 10, 9)), 'FazTyroid_2026-10-09.xlsx');
  });
}
