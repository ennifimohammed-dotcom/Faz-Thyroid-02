import '../models/models.dart';

/// Aide a la lecture : comparaisons a des intervalles enregistres.
/// Aucune prescription n'est produite ici.
enum RangeStatus { low, normal, high, unknown }

enum Level { ok, mild, strong, unknown }

enum Trend { higher, lower, same, unknown }

enum ReadingKey {
  incomplete,
  tshHighFreeNormal,
  tshHighFreeLow,
  tshLowFreeHigh,
  tshLowFreeNormal,
  allNormal,
  tshOnlyHigh,
  tshOnlyLow,
  tshOnlyNormal,
  tshNormalFreeOut,
  other,
}

/// Ecart relatif a la borne : <= seuil => orange, sinon rouge.
const double kMildDeviation = 0.5;

RangeStatus statusOf(double? v, double? min, double? max) {
  if (v == null) return RangeStatus.unknown;
  if (min == null && max == null) return RangeStatus.unknown;
  if (max != null && v > max) return RangeStatus.high;
  if (min != null && v < min) return RangeStatus.low;
  return RangeStatus.normal;
}

Level levelOf(double? v, double? min, double? max) {
  final st = statusOf(v, min, max);
  if (st == RangeStatus.unknown) return Level.unknown;
  if (st == RangeStatus.normal) return Level.ok;
  final bound = st == RangeStatus.high ? max! : min!;
  final diff = (v! - bound).abs();
  final base = bound.abs();
  final deviation = base == 0 ? double.infinity : diff / base;
  return deviation <= kMildDeviation ? Level.mild : Level.strong;
}

class Variation {
  const Variation(this.absolute, this.percent);
  final double? absolute;
  final double? percent;
  bool get available => absolute != null;
}

/// Variation de A vers B. Valeur absente => non disponible (jamais 0).
Variation compareValues(double? a, double? b) {
  if (a == null || b == null) return const Variation(null, null);
  final diff = double.parse((b - a).toStringAsFixed(6));
  final pct =
      a == 0 ? null : double.parse((diff / a.abs() * 100).toStringAsFixed(4));
  return Variation(diff, pct);
}

Trend trendOf(double? previous, double? current) {
  if (previous == null || current == null) return Trend.unknown;
  final d = current - previous;
  if (d.abs() < 1e-9) return Trend.same;
  return d > 0 ? Trend.higher : Trend.lower;
}

ReadingKey readThyroid({
  double? tsh,
  double? ft4,
  double? ft3,
  required RefRanges refs,
}) {
  final t = statusOf(tsh, refs.tshMin, refs.tshMax);
  if (t == RangeStatus.unknown) return ReadingKey.incomplete;
  final free = [
    statusOf(ft4, refs.ft4Min, refs.ft4Max),
    statusOf(ft3, refs.ft3Min, refs.ft3Max),
  ].where((x) => x != RangeStatus.unknown).toList();

  if (free.isEmpty) {
    if (t == RangeStatus.high) return ReadingKey.tshOnlyHigh;
    if (t == RangeStatus.low) return ReadingKey.tshOnlyLow;
    return ReadingKey.tshOnlyNormal;
  }
  final anyLow = free.contains(RangeStatus.low);
  final anyHigh = free.contains(RangeStatus.high);
  final freeOk = !anyLow && !anyHigh;

  if (t == RangeStatus.high) {
    if (freeOk) return ReadingKey.tshHighFreeNormal;
    if (anyLow && !anyHigh) return ReadingKey.tshHighFreeLow;
    return ReadingKey.other;
  }
  if (t == RangeStatus.low) {
    if (freeOk) return ReadingKey.tshLowFreeNormal;
    if (anyHigh && !anyLow) return ReadingKey.tshLowFreeHigh;
    return ReadingKey.other;
  }
  return freeOk ? ReadingKey.allNormal : ReadingKey.tshNormalFreeOut;
}
