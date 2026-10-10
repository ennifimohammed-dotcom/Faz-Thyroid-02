import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatma_zahra_thyroid_tracker/core/medical.dart';
import 'package:fatma_zahra_thyroid_tracker/database/schema.dart';
import 'package:fatma_zahra_thyroid_tracker/features/state/app_state.dart';
import 'package:fatma_zahra_thyroid_tracker/models/models.dart';
import 'package:fatma_zahra_thyroid_tracker/repositories/health_repository.dart';
import 'package:fatma_zahra_thyroid_tracker/widgets/common.dart';

Future<AppState> _state() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final st = AppState(repo: MemoryRepository.seeded(), prefs: prefs);
  await st.load();
  return st;
}

void main() {
  test('photos jointes : ajout, comptage, suppression', () async {
    final st = await _state();
    final entry = st.thyroid.last;
    expect(st.attachmentCount(kAttThyroid, entry.id), 0);

    await st.addAttachment(kAttThyroid, entry.id!, '/tmp/faz_test_a.jpg');
    await st.addAttachment(kAttThyroid, entry.id!, '/tmp/faz_test_b.jpg');
    expect(st.attachmentCount(kAttThyroid, entry.id), 2);
    expect(st.attachmentCount(kAttOther, entry.id), 0);

    await st.deleteAttachment(st.attachmentsFor(kAttThyroid, entry.id).first);
    expect(st.attachmentCount(kAttThyroid, entry.id), 1);

    // supprimer la ligne supprime aussi ses photos
    await st.remove(thyroidT, entry.id!);
    expect(st.attachments, isEmpty);
  });

  test('enregistrement : l\'identifiant est retourné', () async {
    final st = await _state();
    final id = await st.save(
        thyroidT, ThyroidEntry(date: DateTime(2026, 10, 9), tsh: 3.1));
    expect(id, isNonZero);
    await st.attachPending(kAttThyroid, id, ['/tmp/faz_test_c.jpg']);
    expect(st.attachmentCount(kAttThyroid, id), 1);
  });

  test('niveaux de couleur', () {
    expect(levelOf(2, 0.27, 4.2), Level.ok);
    expect(levelOf(4.5, 0.27, 4.2), Level.mild);
    expect(levelOf(11.93, 0.27, 4.2), Level.strong);
    expect(levelOf(0.05, 0.27, 4.2), Level.strong);
    expect(levelOf(144.9, 135, 145), Level.ok);
    expect(levelColor(Level.ok), isNot(levelColor(Level.strong)));
    expect(levelColor(Level.mild), isNot(levelColor(Level.strong)));
  });

  testWidgets('pastille de valeur : texte et flèche', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          ValueChip(label: 'TSH', value: 11.93, min: 0.27, max: 4.2, unit: 'mUI/L'),
          ValueChip(label: 'FT4', value: 14.17, min: 10.6, max: 19.4),
          ValueChip(label: 'X', value: 1, min: 2, max: 5),
          ValueChip(label: 'Y', value: null, min: 2, max: 5),
        ]),
      ),
    ));
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(find.text('TSH 11.93 mUI/L'), findsOneWidget);
    expect(find.text('Y —'), findsOneWidget);
  });
}
