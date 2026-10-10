import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../features/home_shell.dart';
import '../features/state/app_state.dart';
import 'palette.dart';

ThemeData _theme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(seedColor: kRose, brightness: b).copyWith(
    secondary: kLavender,
  );
  final surface = dark ? const Color(0xFF2A1F27) : Colors.white;
  final field = dark ? const Color(0xFF34262F) : const Color(0xFFFFFAFC);
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: c, width: w),
      );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF1C1419) : kBlush,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: scheme.primary,
      titleTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: scheme.primary),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: kRose.withValues(alpha: 0.14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: field,
      border: border(kRose.withValues(alpha: 0.35)),
      enabledBorder: border(kRose.withValues(alpha: 0.30)),
      focusedBorder: border(kRose, 2),
      errorBorder: border(Colors.red.shade400),
      focusedErrorBorder: border(Colors.red.shade400, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kRose,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kRose,
        side: const BorderSide(color: kRose),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kRose,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: CircleBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: kRose.withValues(alpha: 0.18),
      elevation: 0,
      height: 70,
      labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      side: BorderSide(color: kRose.withValues(alpha: 0.3)),
    ),
    dividerTheme: DividerThemeData(color: kRose.withValues(alpha: 0.15)),
    textTheme: base.textTheme.apply(
      bodyColor: dark ? const Color(0xFFF3E6EE) : const Color(0xFF3B2A35),
      displayColor: dark ? const Color(0xFFF3E6EE) : const Color(0xFF3B2A35),
    ),
  );
}

class ThyroidApp extends StatelessWidget {
  const ThyroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return MaterialApp(
      title: 'FazTyroid',
      debugShowCheckedModeBanner: false,
      locale: Locale(st.lang),
      supportedLocales: const [Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: st.dark ? ThemeMode.dark : ThemeMode.light,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const HomeShell(),
    );
  }
}
