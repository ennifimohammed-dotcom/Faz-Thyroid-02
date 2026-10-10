# FazTyroid – Fatma Zahra Belqas / فاطمة الزهراء بلقاس

Application Android (Flutter) **hors ligne** de suivi de l'hypothyroïdie. Les données restent sur le téléphone (SQLite) : pas de compte, pas de publicité, aucune donnée envoyée sur Internet.

> Outil de suivi et d'aide à la lecture uniquement : il ne pose pas de diagnostic et ne prescrit jamais (aucune dose proposée).

## Obtenir l'APK sans rien installer (recommandé)

1. Créez un dépôt sur GitHub et envoyez-y **tout le contenu** de ce dossier (y compris le dossier caché `.github`).
2. Ouvrez l'onglet **Actions** → workflow **Build APK** → attendez la coche verte.
3. Ouvrez l'exécution → section **Artifacts** → téléchargez **app-release-apk** (ZIP contenant `app-release.apk`).

### Release automatique
1. Dans GitHub : **Releases → Draft a new release**, créez le tag `v1.0.0`, publiez.
2. Le workflow compile et attache `app-release.apk` à la Release.
3. Téléchargez l'APK depuis **Releases**.

Pour une nouvelle version : changez `version:` dans `pubspec.yaml` (ex. `1.0.1+2`), puis créez le tag `v1.0.1`.

## Installation locale (facultatif)
Flutter doit être installé. Le dossier `android/` est généré une seule fois :
```bash
flutter create --platforms=android --org com.fatmazahra --project-name fatma_zahra_thyroid_tracker .
rm -f test/widget_test.dart
git checkout -- lib test pubspec.yaml analysis_options.yaml   # si Flutter les a écrasés
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```
L'APK se trouve dans `build/app/outputs/flutter-apk/app-release.apk`.

## Contenu de la version 1.0.0
- Données du fichier Excel préchargées (TSH, FT4, FT3, doses) + Anti-TPO, Anti-TG, ACTH, cortisol (source « donnée fournie par l'utilisateur »).
- Tableau de bord, historique, timeline, comparaison de deux dates, graphiques (axes séparés).
- Lecture prudente des résultats (« à discuter avec le médecin »).
- Levothyrox : dose saisie / prescrite / réellement prise, timeline.
- Consultations, autres analyses, journal des symptômes.
- Photos des analyses (galerie ou appareil photo) jointes aux bilans et autres analyses, avec visionneuse zoomable.
- Codes couleur (vert normal, orange légèrement hors intervalle, rouge fortement hors intervalle, flèches ↑↓✓) dans Analyses, Timeline et Traitement.
- Arabe (RTL) / français, thème clair/sombre, valeurs de référence modifiables.
- Export Excel (.xlsx) complet : résumé, historique médical complet par date, bilans thyroïdiens, Levothyrox, consultations, autres analyses, symptômes, valeurs de référence. Enregistré dans Téléchargements (Android 10+), partageable, historique copiable en texte.

## Notes techniques
- L'export n'utilise aucun plugin tiers : un petit pont Kotlin (`tool/MainActivity.body.kt`) est injecté dans `MainActivity` par le workflow après `flutter create`.

## Pas encore inclus (prévu pour une version suivante)
Rappels de prise et de contrôle (notifications), export PDF, import Excel, verrouillage PIN.
