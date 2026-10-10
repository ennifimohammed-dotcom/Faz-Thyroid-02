import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'database/sqlite_repository.dart';
import 'features/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repo = await SqliteRepository.open();
  final state = AppState(repo: repo, prefs: prefs);
  await state.load();
  runApp(ChangeNotifierProvider<AppState>.value(
      value: state, child: const ThyroidApp()));
}
