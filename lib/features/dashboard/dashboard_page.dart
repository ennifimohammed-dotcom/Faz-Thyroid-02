import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/palette.dart';
import '../../core/format.dart';
import '../../core/medical.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import '../state/app_state.dart';
import '../settings/forms.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    final refs = st.refs;
    final tshE = st.lastWith((e) => e.tsh);
    final ft4E = st.lastWith((e) => e.ft4);
    final ft3E = st.lastWith((e) => e.ft3);
    final doseE = st.lastWith((e) => e.doseUg);
    final lastDate = st.thyroid.isEmpty ? null : st.thyroid.last.date;
    final prescribed = st.latestPrescribed;
    final next = st.nextControlDate;
    final na = s.t('not_available');
    final name = st.lang == 'ar' ? st.profile.nameAr : st.profile.nameFr;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Header(
          greeting: s.t('greeting'),
          name: name,
          subtitle: lastDate == null
              ? s.t('take_care')
              : '${s.t('last_bilan')} : ${formatDate(lastDate)}',
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
          child: Text(s.t('current_state'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700, color: kRoseDeep)),
        ),
        MetricCard(
            s: s,
            icon: Icons.auto_graph_rounded,
            label: s.t('last_tsh'),
            value: tshE?.tsh,
            unit: refs.tshUnit,
            min: refs.tshMin,
            max: refs.tshMax,
            date: tshE?.date),
        MetricCard(
            s: s,
            icon: Icons.water_drop_rounded,
            label: s.t('last_ft4'),
            value: ft4E?.ft4,
            unit: refs.ft4Unit,
            min: refs.ft4Min,
            max: refs.ft4Max,
            date: ft4E?.date),
        MetricCard(
            s: s,
            icon: Icons.opacity_rounded,
            label: s.t('last_ft3'),
            value: ft3E?.ft3,
            unit: refs.ft3Unit,
            min: refs.ft3Min,
            max: refs.ft3Max,
            date: ft3E?.date),
        SectionCard(
          title: s.t('levothyrox'),
          icon: Icons.medication_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledLine(
                  s.t('last_dose'),
                  doseE == null
                      ? na
                      : '${formatNum(doseE.doseUg)} µg (${formatDate(doseE.date)})'),
              if (prescribed != null)
                LabeledLine(
                    s.t('prescribed_dose'),
                    '${formatNum(prescribed.doseUg)} µg (${prescribed.date == null ? s.t('date_unknown') : formatDate(prescribed.date!)})'),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.event_rounded,
          title: s.t('next_control'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledLine(s.t('last_bilan'),
                  lastDate == null ? na : formatDate(lastDate)),
              LabeledLine(
                  s.t('date'),
                  next == null
                      ? s.t('not_set')
                      : '${st.profile.nextControlWhat.isEmpty ? '' : '${st.profile.nextControlWhat} – '}${formatDate(next)}'),
            ],
          ),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NextControlScreen())),
        ),
        _EvolutionCard(st: st),
        _ReadingCard(st: st),
        const SizedBox(height: 4),
        Text(s.t('disclaimer'),
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.s,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.date,
  });
  final S s;
  final IconData icon;
  final String label, unit;
  final double? value, min, max;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final level = levelOf(value, min, max);
    final status = statusOf(value, min, max);
    final color = levelColor(level);
    final ref = (min == null && max == null)
        ? s.t('not_set')
        : '${formatNum(min, na: '…')} – ${formatNum(max, na: '…')} $unit';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                          value == null
                              ? s.t('not_available')
                              : formatNum(value),
                          style: TextStyle(
                              fontSize: value == null ? 18 : 34,
                              fontWeight: FontWeight.w800,
                              color: color)),
                      const SizedBox(width: 6),
                      if (value != null) Text(unit),
                    ],
                  ),
                  Text('${s.t('ref')} : $ref',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (date != null)
                    Text(formatDate(date!),
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (value != null)
              StatusChip(label: statusLabel(s, status), color: color),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.greeting, required this.name, required this.subtitle});
  final String greeting, name, subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kHeaderGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: kRose.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: const TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 4),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle),
            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}

class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard({required this.st});
  final AppState st;

  @override
  Widget build(BuildContext context) {
    final s = st.s;
    final cur = st.lastWith((e) => e.tsh);
    final prev = st.lastWith((e) => e.tsh, skip: 1);
    final status = statusOf(cur?.tsh, st.refs.tshMin, st.refs.tshMax);
    final lines = <String>[
      s.t('evo_tsh_${status.name}'),
    ];
    final trend = trendOf(prev?.tsh, cur?.tsh);
    if (trend != Trend.unknown) lines.add(s.t('evo_prev_${trend.name}'));
    return SectionCard(
      title: s.t('evolution'),
      icon: Icons.trending_up_rounded,
      child: Text(lines.join(' ')),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.st});
  final AppState st;

  @override
  Widget build(BuildContext context) {
    final s = st.s;
    final e = st.lastWith((e) => e.tsh);
    final key = readThyroid(
        tsh: e?.tsh, ft4: e?.ft4, ft3: e?.ft3, refs: st.refs);
    return SectionCard(
      title: s.t('reading'),
      icon: Icons.favorite_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (e != null)
            Text(formatDate(e.date),
                style: Theme.of(context).textTheme.bodySmall),
          Text(s.t('read_${key.name}')),
          const SizedBox(height: 8),
          Text(s.t('discuss_doctor'),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
