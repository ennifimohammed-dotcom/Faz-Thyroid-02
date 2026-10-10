import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/palette.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../state/app_state.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    final r = st.refs;
    final tsh = st.points((e) => e.tsh);
    final ft4 = st.points((e) => e.ft4);
    final ft3 = st.points((e) => e.ft3);
    final dose = st.points((e) => e.doseUg);

    final all = [...tsh, ...ft4, ...ft3, ...dose];
    double? xMin, xMax;
    if (all.isNotEmpty) {
      xMin = all.map((p) => p.x).reduce((a, b) => a < b ? a : b);
      xMax = all.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    }

    Widget card(String title, List<ChartPoint> pts, Color color,
        {double? min, double? max, bool shared = false}) {
      return SectionCard(
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (min != null || max != null)
              Text('${s.t('ref_band')} : ${min ?? '…'} – ${max ?? '…'}',
                  style: Theme.of(context).textTheme.bodySmall),
            TrendChart(
              points: pts,
              color: color,
              emptyText: s.t('no_data'),
              refMin: min,
              refMax: max,
              xMin: shared ? xMin : null,
              xMax: shared ? xMax : null,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(s.t('charts_separate'),
            style: Theme.of(context).textTheme.titleMedium),
        card('TSH (${r.tshUnit})', tsh, kRose,
            min: r.tshMin, max: r.tshMax),
        card('FT4 (${r.ft4Unit})', ft4, kLavender,
            min: r.ft4Min, max: r.ft4Max),
        card('FT3 (${r.ft3Unit})', ft3, kSky,
            min: r.ft3Min, max: r.ft3Max),
        card('${s.t('dose_short')} Levothyrox (µg)', dose, kPeach),
        const SizedBox(height: 8),
        Text(s.t('charts_compare'),
            style: Theme.of(context).textTheme.titleMedium),
        Text(s.t('charts_note'), style: Theme.of(context).textTheme.bodySmall),
        card('TSH (${r.tshUnit})', tsh, kRose,
            min: r.tshMin, max: r.tshMax, shared: true),
        card('FT4 (${r.ft4Unit})', ft4, kLavender,
            min: r.ft4Min, max: r.ft4Max, shared: true),
        card('${s.t('dose_short')} Levothyrox (µg)', dose, kPeach,
            shared: true),
      ],
    );
  }
}
