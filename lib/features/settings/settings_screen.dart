import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'forms.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    void open(Widget w) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(title: Text(s.t('menu_settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.t('language'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ar', label: Text('العربية')),
              ButtonSegment(value: 'fr', label: Text('Français')),
            ],
            selected: {st.lang},
            onSelectionChanged: (v) => st.setLang(v.first),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(s.t('theme_dark')),
            value: st.dark,
            onChanged: st.setDark,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(s.t('profile')),
            onTap: () => open(const ProfileScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: Text(s.t('ref_values')),
            onTap: () => open(const RefsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: Text(s.t('next_control')),
            onTap: () => open(const NextControlScreen()),
          ),
          const Divider(),
          Text(s.t('privacy_note'), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(s.t('disclaimer'), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
