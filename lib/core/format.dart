/// Utilitaires de dates et de nombres (chiffres toujours 0-9, independants de la locale).
String two(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

String formatShortDate(DateTime d) =>
    '${two(d.day)}/${two(d.month)}/${two(d.year % 100)}';

String toIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';

DateTime? fromIso(Object? s) =>
    (s is String && s.isNotEmpty) ? DateTime.tryParse(s) : null;

/// Convertit les chiffres arabes et le separateur decimal arabe en ASCII.
String normalizeDigits(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final b = StringBuffer();
  for (final ch in input.split('')) {
    final a = arabic.indexOf(ch);
    final p = persian.indexOf(ch);
    if (a >= 0) {
      b.write(a);
    } else if (p >= 0) {
      b.write(p);
    } else if (ch == '٫' || ch == ',') {
      b.write('.');
    } else if (ch == '٬') {
      // separateur de milliers arabe : ignore
    } else {
      b.write(ch);
    }
  }
  return b.toString();
}

/// Date stricte jj/mm/aaaa. Retourne null si invalide (ex. 31/02/2026).
DateTime? parseDate(String input) {
  final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$')
      .firstMatch(normalizeDigits(input).trim());
  if (m == null) return null;
  final d = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final y = int.parse(m.group(3)!);
  if (y < 1900 || y > 2200) return null;
  final dt = DateTime(y, mo, d);
  if (dt.year != y || dt.month != mo || dt.day != d) return null;
  return dt;
}

/// Nombre decimal ; accepte "11,93" et "11.93". Vide ou invalide => null.
double? parseNumber(String input) {
  final s = normalizeDigits(input).trim();
  if (s.isEmpty) return null;
  final v = double.tryParse(s);
  if (v == null || !v.isFinite) return null;
  return v;
}

double? asDouble(Object? o) => o is num ? o.toDouble() : null;

/// Affiche un nombre sans zeros inutiles ; null => [na] (jamais "0").
String formatNum(double? v, {String na = ''}) {
  if (v == null) return na;
  if (v == v.roundToDouble()) return v.round().toString();
  var s = v.toStringAsFixed(4);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}
