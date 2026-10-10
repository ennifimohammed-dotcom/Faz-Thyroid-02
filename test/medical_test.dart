import 'package:flutter_test/flutter_test.dart';
import 'package:fatma_zahra_thyroid_tracker/core/format.dart';
import 'package:fatma_zahra_thyroid_tracker/core/medical.dart';
import 'package:fatma_zahra_thyroid_tracker/models/models.dart';

void main() {
  final refs = RefRanges.defaults();

  group('états TSH / FT4 / FT3', () {
    test('TSH', () {
      expect(statusOf(11.93, refs.tshMin, refs.tshMax), RangeStatus.high);
      expect(statusOf(20.9, refs.tshMin, refs.tshMax), RangeStatus.high);
      expect(statusOf(2.0, refs.tshMin, refs.tshMax), RangeStatus.normal);
      expect(statusOf(0.1, refs.tshMin, refs.tshMax), RangeStatus.low);
      expect(statusOf(null, refs.tshMin, refs.tshMax), RangeStatus.unknown);
      expect(statusOf(2.0, null, null), RangeStatus.unknown);
    });
    test('FT4 et FT3 (valeurs exactes 14 et 3.5)', () {
      expect(statusOf(14, refs.ft4Min, refs.ft4Max), RangeStatus.normal);
      expect(statusOf(3.5, refs.ft3Min, refs.ft3Max), RangeStatus.normal);
      expect(statusOf(9, refs.ft4Min, refs.ft4Max), RangeStatus.low);
      expect(statusOf(9, refs.ft3Min, refs.ft3Max), RangeStatus.high);
    });
    test('niveaux de couleur', () {
      expect(levelOf(2, refs.tshMin, refs.tshMax), Level.ok);
      expect(levelOf(4.5, refs.tshMin, refs.tshMax), Level.mild);
      expect(levelOf(11.93, refs.tshMin, refs.tshMax), Level.strong);
      expect(levelOf(null, refs.tshMin, refs.tshMax), Level.unknown);
    });
  });

  group('comparaison et variation', () {
    test('différence et pourcentage', () {
      final v = compareValues(10.9, 11.93);
      expect(v.absolute, closeTo(1.03, 1e-9));
      expect(v.percent, closeTo(9.4495, 1e-3));
    });
    test('valeur absente => non disponible, jamais zéro', () {
      expect(compareValues(null, 5).available, isFalse);
      expect(compareValues(5, null).absolute, isNull);
    });
    test('départ à zéro : pas de pourcentage', () {
      final v = compareValues(0, 5);
      expect(v.absolute, 5);
      expect(v.percent, isNull);
    });
    test('tendance', () {
      expect(trendOf(8, 11), Trend.higher);
      expect(trendOf(11, 8), Trend.lower);
      expect(trendOf(8, 8), Trend.same);
      expect(trendOf(null, 8), Trend.unknown);
    });
  });

  group('lecture des résultats', () {
    test('cas du 28/09/2026', () {
      expect(readThyroid(tsh: 11.93, ft4: 14, ft3: 3.5, refs: refs),
          ReadingKey.tshHighFreeNormal);
    });
    test('TSH manquant', () {
      expect(readThyroid(tsh: null, ft4: 14, refs: refs), ReadingKey.incomplete);
    });
    test('TSH seul', () {
      expect(readThyroid(tsh: 20.9, refs: refs), ReadingKey.tshOnlyHigh);
    });
    test('tout normal', () {
      expect(readThyroid(tsh: 2, ft4: 14, ft3: 4, refs: refs), ReadingKey.allNormal);
    });
  });

  group('dates et nombres', () {
    test('validation des dates', () {
      expect(parseDate('28/09/2026'), DateTime(2026, 9, 28));
      expect(parseDate('31/02/2026'), isNull);
      expect(parseDate('2026-09-28'), isNull);
      expect(parseDate(''), isNull);
      expect(formatDate(DateTime(2026, 1, 7)), '07/01/2026');
    });
    test('nombres', () {
      expect(parseNumber('11,93'), 11.93);
      expect(parseNumber(''), isNull);
      expect(parseNumber('abc'), isNull);
      expect(parseNumber('NaN'), isNull);
      expect(parseNumber('٣٫٥'), 3.5);
    });
    test('affichage sans zéros inutiles', () {
      expect(formatNum(14.0), '14');
      expect(formatNum(11.93), '11.93');
      expect(formatNum(null, na: 'Non disponible'), 'Non disponible');
    });
  });
}
