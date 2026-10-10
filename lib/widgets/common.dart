import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app/palette.dart';
import '../core/format.dart';
import '../core/medical.dart';
import '../l10n/strings.dart';
import '../models/models.dart';

Color levelColor(Level l) {
  switch (l) {
    case Level.ok:
      return kMint;
    case Level.mild:
      return const Color(0xFFEF9A4B);
    case Level.strong:
      return const Color(0xFFE0506F);
    case Level.unknown:
      return Colors.grey;
  }
}

String statusLabel(S s, RangeStatus st) => s.t('status_${st.name}');

String sourceLabel(S s, String source) {
  final edited = source.endsWith('+edit');
  final base = edited ? source.substring(0, source.length - 5) : source;
  final key = base == kSrcExcel
      ? 'src_excel'
      : base == kSrcUser
          ? 'src_user'
          : 'src_manual';
  return edited ? '${s.t(key)} ${s.t('edited_suffix')}' : s.t(key);
}

List<Widget> gap(List<Widget> items) => [
      for (final w in items) ...[w, const SizedBox(height: 12)],
    ];

Future<bool> confirmDialog(BuildContext context, S s, String message) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(s.t('cancel'))),
        FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(s.t('confirm'))),
      ],
    ),
  );
  return r ?? false;
}

class SectionCard extends StatelessWidget {
  const SectionCard(
      {super.key, this.title, required this.child, this.onTap, this.icon});
  final String? title;
  final Widget child;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                            color: kRose.withValues(alpha: 0.12),
                            shape: BoxShape.circle),
                        child: Icon(icon, size: 18, color: kRose),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(title!,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastille d'etat arrondie (Normal / Eleve / Faible...).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
    );
  }
}

class LabeledLine extends StatelessWidget {
  const LabeledLine(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 110,
              child: Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.controller,
    required this.label,
    required this.s,
    this.required = true,
  });
  final TextEditingController controller;
  final String label;
  final S s;
  final bool required;

  Future<void> _pick(BuildContext context) async {
    final initial = parseDate(controller.text) ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (d != null) controller.text = formatDate(d);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        hintText: s.t('date_hint'),
        suffixIcon: IconButton(
            icon: const Icon(Icons.event_rounded, color: kRose),
            onPressed: () => _pick(context)),
      ),
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return required ? s.t('err_required') : null;
        return parseDate(t) == null ? s.t('err_date') : null;
      },
    );
  }
}

Widget numField(S s, TextEditingController c, String label, {String? suffix}) {
  return TextFormField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,),
    validator: (v) {
      final t = (v ?? '').trim();
      if (t.isEmpty) return null;
      final n = parseNumber(t);
      return (n == null || n < 0) ? s.t('err_number') : null;
    },
  );
}

Widget textField(TextEditingController c, String label,
    {int maxLines = 1, String? Function(String?)? validator}) {
  return TextFormField(
    controller: c,
    maxLines: maxLines,
    decoration:
        InputDecoration(labelText: label,),
    validator: validator,
  );
}

/// Page de formulaire standard : titre, champs, bouton Enregistrer.
class FormPage extends StatelessWidget {
  const FormPage({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.onSave,
    required this.saveLabel,
  });
  final String title, saveLabel;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...gap(children),
            FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: Text(saveLabel)),
          ],
        ),
      ),
    );
  }
}

/// Graphique de tendance (fl_chart) avec bande de reference optionnelle.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.points,
    required this.color,
    required this.emptyText,
    this.refMin,
    this.refMax,
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
    this.height = 200,
  });
  final List<ChartPoint> points;
  final Color color;
  final String emptyText;
  final double? refMin, refMax, xMin, xMax, yMin, yMax;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(height: 70, child: Center(child: Text(emptyText)));
    }
    final xs = points.map((p) => p.x);
    var minX = xMin ?? xs.reduce(math.min);
    var maxX = xMax ?? xs.reduce(math.max);
    if (maxX - minX < 1) {
      minX -= 1;
      maxX += 1;
    }
    final values = points.map((p) => p.value);
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    final rMin = refMin;
    final rMax = refMax;
    if (rMin != null) lo = math.min(lo, rMin);
    if (rMax != null) hi = math.max(hi, rMax);
    final pad = (hi - lo) == 0 ? 1.0 : (hi - lo) * 0.15;
    final minY = yMin ?? math.max(0.0, lo - pad);
    final maxY = yMax ?? hi + pad;
    final green = Colors.green.shade600;

    String axisNum(double v) => formatNum(double.parse(v.toStringAsFixed(2)));

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
        child: LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: [
                if (rMin != null && rMax != null)
                  HorizontalRangeAnnotation(
                      y1: rMin, y2: rMax, color: green.withValues(alpha: 0.12)),
              ],
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (rMin != null)
                  HorizontalLine(
                      y: rMin, color: green, strokeWidth: 1, dashArray: [6, 4]),
                if (rMax != null)
                  HorizontalLine(
                      y: rMax, color: green, strokeWidth: 1, dashArray: [6, 4]),
              ],
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  getTitlesWidget: (v, meta) => Text(axisNum(v),
                      style: const TextStyle(fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (maxX - minX) / 3,
                  getTitlesWidget: (v, meta) {
                    final d = DateTime.fromMillisecondsSinceEpoch(
                        (v * 86400000).round());
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(formatShortDate(d),
                          style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (final p in points) FlSpot(p.x, p.value)],
                isCurved: false,
                color: color,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastille de valeur colorée : couleur = niveau, flèche = sens.
/// ↑ au-dessus de l'intervalle, ↓ en dessous, ✓ dans l'intervalle.
class ValueChip extends StatelessWidget {
  const ValueChip({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.unit = '',
  });
  final String label, unit;
  final double? value, min, max;

  @override
  Widget build(BuildContext context) {
    final status = statusOf(value, min, max);
    final color = levelColor(levelOf(value, min, max));
    final IconData icon;
    switch (status) {
      case RangeStatus.high:
        icon = Icons.arrow_upward_rounded;
        break;
      case RangeStatus.low:
        icon = Icons.arrow_downward_rounded;
        break;
      case RangeStatus.normal:
        icon = Icons.check_rounded;
        break;
      case RangeStatus.unknown:
        icon = Icons.remove_rounded;
        break;
    }
    final text = value == null
        ? '$label —'
        : '$label ${formatNum(value)}${unit.isEmpty ? '' : ' $unit'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(width: 4),
          Icon(icon, size: 16, color: color),
        ],
      ),
    );
  }
}

/// Légende des couleurs, affichée en haut des listes.
class ColorLegend extends StatelessWidget {
  const ColorLegend({super.key, required this.s});
  final S s;

  Widget _item(Color c, String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(fontSize: 12.5)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          _item(levelColor(Level.ok), s.t('legend_normal')),
          _item(levelColor(Level.mild), s.t('legend_mild')),
          _item(levelColor(Level.strong), s.t('legend_strong')),
          Text(s.t('legend_arrows'), style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }
}
