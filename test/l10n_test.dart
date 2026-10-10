import 'package:flutter_test/flutter_test.dart';
import 'package:fatma_zahra_thyroid_tracker/l10n/strings.dart';

void main() {
  test('mêmes clés en français et en arabe', () {
    expect(S.keysOf('fr'), S.keysOf('ar'));
  });

  test('changement de langue', () {
    const fr = S('fr');
    const ar = S('ar');
    expect(fr.rtl, isFalse);
    expect(ar.rtl, isTrue);
    expect(fr.t('nav_home'), 'Accueil');
    expect(ar.t('nav_home'), isNot(fr.t('nav_home')));
    expect(fr.t('not_available'), 'Non disponible');
  });

  test('aucune formulation de prescription', () {
    const banned = ['Augmentez', 'Diminuez', 'Arrêtez', 'Commencez'];
    for (final k in S.keysOf('fr')) {
      final text = const S('fr').t(k);
      for (final b in banned) {
        expect(text.contains(b), isFalse, reason: '$k contient $b');
      }
    }
  });
}
