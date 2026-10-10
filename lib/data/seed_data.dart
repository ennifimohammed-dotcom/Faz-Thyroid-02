import '../models/models.dart';

/// Donnees initiales issues du fichier Excel « Suivi_Thyroide.xlsx »
/// (feuilles Suivi TSH_T4 et Autres_Analyses), recopiees sans arrondi ni
/// correction. La colonne « Poids » du fichier est vide : rien n'est invente.
final List<ThyroidEntry> seedThyroid = [
  ThyroidEntry(date: DateTime(2023, 3, 9), tsh: 0, comment: 'Valeur 0 dans le fichier Excel d’origine (à vérifier).', source: kSrcExcel),
  ThyroidEntry(date: DateTime(2023, 3, 28), tsh: 0.05, ft4: 18.35, ft3: 3.83, source: kSrcExcel),
  ThyroidEntry(date: DateTime(2023, 5, 8), tsh: 13.26, ft4: 11.91, ft3: 4.29, source: kSrcExcel),
  ThyroidEntry(date: DateTime(2023, 9, 11), tsh: 5.86, source: kSrcExcel),
  ThyroidEntry(date: DateTime(2023, 12, 18), tsh: 2.23, source: kSrcExcel),
  ThyroidEntry(date: DateTime(2025, 2, 4), tsh: 0.024, source: kSrcExcel),
  ThyroidEntry(date: DateTime(2025, 11, 11), tsh: 20.9, doseUg: 100, source: kSrcExcel),
  ThyroidEntry(date: DateTime(2026, 1, 17), tsh: 8.48, doseUg: 75, source: kSrcExcel),
  ThyroidEntry(date: DateTime(2026, 5, 8), tsh: 10.9, doseUg: 75, source: kSrcExcel),
  ThyroidEntry(date: DateTime(2026, 9, 28), tsh: 11.93, ft4: 14.17, ft3: 3.4, doseUg: 75, source: kSrcExcel),
];

final List<OtherAnalysis> seedOthers = [
  OtherAnalysis(date: DateTime(2023, 4, 18), name: 'ACTH', value: 16.53, unit: 'pg/ml', refMin: 7.2, refMax: 63.3, comment: 'État indiqué dans le fichier : Normale.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 4, 10), name: 'ACTH', value: 9.3, unit: 'pg/ml', refMin: 7.2, refMax: 63.3, comment: 'État indiqué dans le fichier : Normale.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 4, 11), name: 'Anticorps ATPO', value: 196.59, unit: 'IU/ml', refMax: 50, comment: 'Bornes du fichier : Vmin <50 ; Vmax >75. État indiqué dans le fichier : Elevé.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 4, 11), name: 'Anticorps ATG', value: 79.4, unit: 'IU/ml', refMax: 100, comment: 'Bornes du fichier : Vmin <100 ; Vmax >150. État indiqué dans le fichier : Normale.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 3, 29), name: 'Sodium', value: 145.51, unit: 'mmol/l', refMin: 135, refMax: 145, comment: 'État indiqué dans le fichier : Elevé.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 3, 29), name: 'Potassium', value: 4.48, unit: 'mmol/l', refMin: 3.5, refMax: 5.3, comment: 'État indiqué dans le fichier : Normale.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 7, 18), name: 'Sodium', value: 144.9, unit: 'mmol/l', refMin: 135, refMax: 145, comment: 'État indiqué dans le fichier : Elevé.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 7, 18), name: 'Potassium', value: 3.75, unit: 'mmol/l', refMin: 3.5, refMax: 5.3, comment: 'État indiqué dans le fichier : Faible.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 9, 11), name: 'Sodium', value: 145.7, unit: 'mmol/l', refMin: 135, refMax: 145, comment: 'État indiqué dans le fichier : Elevé.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 9, 11), name: 'Potassium', value: 3.89, unit: 'mmol/l', refMin: 3.5, refMax: 5.3, comment: 'État indiqué dans le fichier : Normale.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 12, 18), name: 'Sodium', value: 135.1, unit: 'mmol/l', refMin: 135, refMax: 145, comment: 'État indiqué dans le fichier : Faible.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 12, 18), name: 'Potassium', value: 3.9, unit: 'mmol/l', refMin: 3.5, refMax: 5.3, comment: 'État indiqué dans le fichier : Normale.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 3, 31), name: 'Cortisol 8H', value: 24.7, unit: 'µg/l', refMin: 54.94, refMax: 287.15, comment: 'État indiqué dans le fichier : Faible.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 9, 11), name: 'Cortisol 8H', value: 127.52, unit: 'µg/l', refMin: 54.94, refMax: 287.15, comment: 'État indiqué dans le fichier : Normale.', source: kSrcExcel),
  OtherAnalysis(date: DateTime(2023, 12, 18), name: 'Cortisol 8H', value: 190.57, unit: 'µg/l', refMin: 54.94, refMax: 287.15, comment: 'État indiqué dans le fichier : Normale.', source: kSrcExcel),
  // Donnee fournie directement par l’utilisateur (absente du fichier Excel).
  OtherAnalysis(
      date: DateTime(2026, 10, 3),
      name: 'Cortisol matin',
      value: 139.1,
      unit: 'ng/mL',
      refMin: 82.2,
      refMax: 195,
      source: kSrcUser),
];

/// Aucun evenement de dose prescrite initial : le fichier Excel indique
/// 75 µg au 28/09/2026 (colonne Dose Levothyrox).
final List<DoseEvent> seedDoseEvents = [];
