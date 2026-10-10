import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/palette.dart';
import 'analyses/other_analyses_screen.dart';
import 'consultations/consultations_page.dart';
import 'dashboard/dashboard_page.dart';
import 'settings/export_screen.dart';
import 'settings/settings_screen.dart';
import 'state/app_state.dart';
import 'symptoms/symptoms_screen.dart';
import 'thyroid/analyses_page.dart';
import 'thyroid/charts_page.dart';
import 'thyroid/thyroid_form.dart';
import 'treatment/treatment_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _push(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  Widget? _fab(String tooltip) {
    Widget? target;
    if (_index == 1) target = const ThyroidFormScreen();
    if (_index == 3) target = const DoseFormScreen();
    if (_index == 4) target = const ConsultationFormScreen();
    if (target == null) return null;
    final t = target;
    return FloatingActionButton(
      tooltip: tooltip,
      onPressed: () => _push(t),
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    final titles = [
      s.t('app_title'),
      s.t('nav_analyses'),
      s.t('nav_charts'),
      s.t('nav_treatment'),
      s.t('nav_consult'),
    ];
    const pages = [
      DashboardPage(),
      AnalysesPage(),
      ChartsPage(),
      TreatmentPage(),
      ConsultationsPage(),
    ];
    void drawerOpen(Widget w) {
      Navigator.pop(context);
      _push(w);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          if (_index == 1 || _index == 0)
            IconButton(
              tooltip: s.t('compare'),
              icon: const Icon(Icons.compare_arrows),
              onPressed: () => _push(const CompareScreen()),
            ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: kHeaderGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.spa_rounded, color: Colors.white, size: 30),
                    const SizedBox(height: 10),
                    Text(
                        st.lang == 'ar' ? st.profile.nameAr : st.profile.nameFr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text(s.t('app_title'),
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                  leading: const Icon(Icons.sick_outlined),
                  title: Text(s.t('menu_symptoms')),
                  onTap: () => drawerOpen(const SymptomsScreen())),
              ListTile(
                  leading: const Icon(Icons.biotech_outlined),
                  title: Text(s.t('menu_other')),
                  onTap: () => drawerOpen(const OtherAnalysesScreen())),
              ListTile(
                  leading: const Icon(Icons.table_view_rounded),
                  title: Text(s.t('menu_export')),
                  onTap: () => drawerOpen(const ExportScreen())),
              ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(s.t('menu_settings')),
                  onTap: () => drawerOpen(const SettingsScreen())),
            ],
          ),
        ),
      ),
      body: pages[_index],
      floatingActionButton: _fab(s.t('add')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: s.t('nav_home')),
          NavigationDestination(
              icon: const Icon(Icons.science_outlined),
              selectedIcon: const Icon(Icons.science),
              label: s.t('nav_analyses')),
          NavigationDestination(
              icon: const Icon(Icons.show_chart),
              selectedIcon: const Icon(Icons.stacked_line_chart),
              label: s.t('nav_charts')),
          NavigationDestination(
              icon: const Icon(Icons.medication_outlined),
              selectedIcon: const Icon(Icons.medication),
              label: s.t('nav_treatment')),
          NavigationDestination(
              icon: const Icon(Icons.local_hospital_outlined),
              selectedIcon: const Icon(Icons.local_hospital),
              label: s.t('nav_consult')),
        ],
      ),
    );
  }
}
