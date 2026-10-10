import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatma_zahra_thyroid_tracker/features/dashboard/dashboard_page.dart';
import 'package:fatma_zahra_thyroid_tracker/features/state/app_state.dart';
import 'package:fatma_zahra_thyroid_tracker/repositories/health_repository.dart';

Future<AppState> _state() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(repo: MemoryRepository.seeded(), prefs: prefs);
  await state.load();
  return state;
}

void main() {
  test('tableau de bord v2 : données dérivées (sans interface)', () async {
    final st = await _state();
    expect(st.lastWith((e) => e.tsh)?.tsh, 11.93);
    expect(st.lastWith((e) => e.ft4)?.ft4, 14.17);
    expect(st.lastWith((e) => e.ft3)?.ft3, 3.4);
    expect(st.lastWith((e) => e.doseUg)?.doseUg, 75);
    expect(st.lastWith((e) => e.tsh, skip: 1)?.tsh, 10.9);
    expect(st.latestPrescribed, isNull);
    expect(st.doseItems.length, 4);
  });

  testWidgets('tableau de bord v2 : affichage', (tester) async {
    final state = await _state();

    // Grand écran logique (ratio 1.0) : pas de débordement ni de contenu
    // hors zone construite par la liste.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(900, 8000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('fr')],
          home: Scaffold(body: DashboardPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('11.93'), findsWidgets);
    expect(find.textContaining('3.4'), findsWidgets);
    expect(find.textContaining('75 µg'), findsWidgets);
    expect(find.textContaining('médecin'), findsWidgets);
  });
}
