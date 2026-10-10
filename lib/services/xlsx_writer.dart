import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Ecrivain .xlsx minimal et autonome (aucune dependance externe).
/// Produit un classeur Office Open XML valide, ouvrable dans Excel,
/// LibreOffice et Google Sheets. Les textes sont des chaines directes,
/// donc entierement selectionnables et copiables.

const int kStyleDefault = 0;
const int kStyleDate = 1;
const int kStyleHeader = 2;
const int kStyleTitle = 3;
const int kStyleWrap = 4;
const int kStyleLabel = 5;

class XCell {
  const XCell(this.value, [this.style = kStyleDefault]);
  final Object? value;
  final int style;
}

class XSheet {
  XSheet(
    this.name,
    this.rows, {
    this.widths = const [],
    this.header = false,
    this.rtl = false,
  });

  final String name;
  final List<List<Object?>> rows;
  final List<double> widths;

  /// Premiere ligne = en-tete (style, volet fige, filtre automatique).
  final bool header;
  final bool rtl;
}

String xlsxColumnName(int index) {
  var n = index;
  var s = '';
  do {
    s = String.fromCharCode(65 + n % 26) + s;
    n = n ~/ 26 - 1;
  } while (n >= 0);
  return s;
}

/// Numero de serie Excel (jours depuis le 30/12/1899).
int xlsxDateSerial(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(1899, 12, 30))
        .inDays;

String xlsxEscape(String s) {
  final b = StringBuffer();
  for (final u in s.runes) {
    if (u < 0x20 && u != 0x09 && u != 0x0A && u != 0x0D) continue;
    switch (u) {
      case 0x26:
        b.write('&amp;');
        break;
      case 0x3C:
        b.write('&lt;');
        break;
      case 0x3E:
        b.write('&gt;');
        break;
      case 0x22:
        b.write('&quot;');
        break;
      case 0x27:
        b.write('&apos;');
        break;
      default:
        b.writeCharCode(u);
    }
  }
  return b.toString();
}

String _cellXml(int r, int c, Object? raw, {int? forcedStyle}) {
  Object? v = raw;
  int? style = forcedStyle;
  if (raw is XCell) {
    v = raw.value;
    style = raw.style;
  }
  final ref = '${xlsxColumnName(c)}${r + 1}';
  if (v == null) {
    return style == null ? '' : '<c r="$ref" s="$style"/>';
  }
  if (v is DateTime) {
    return '<c r="$ref" s="${style ?? kStyleDate}"><v>${xlsxDateSerial(v)}</v></c>';
  }
  if (v is num) {
    if (v is double && !v.isFinite) return '';
    return '<c r="$ref" s="${style ?? kStyleDefault}"><v>$v</v></c>';
  }
  final text = xlsxEscape(v.toString());
  return '<c r="$ref" s="${style ?? kStyleWrap}" t="inlineStr"><is><t xml:space="preserve">$text</t></is></c>';
}

String _sheetXml(XSheet s) {
  var cols = 0;
  for (final r in s.rows) {
    cols = math.max(cols, r.length);
  }
  final b = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
  final rtl = s.rtl ? ' rightToLeft="1"' : '';
  if (s.header) {
    b.write('<sheetViews><sheetView workbookViewId="0"$rtl>'
        '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
        '<selection pane="bottomLeft"/></sheetView></sheetViews>');
  } else {
    b.write('<sheetViews><sheetView workbookViewId="0"$rtl/></sheetViews>');
  }
  b.write('<sheetFormatPr defaultRowHeight="15"/>');
  if (s.widths.isNotEmpty) {
    b.write('<cols>');
    for (var i = 0; i < s.widths.length; i++) {
      b.write('<col min="${i + 1}" max="${i + 1}" width="${s.widths[i]}" customWidth="1"/>');
    }
    b.write('</cols>');
  }
  b.write('<sheetData>');
  for (var r = 0; r < s.rows.length; r++) {
    b.write('<row r="${r + 1}">');
    final row = s.rows[r];
    for (var c = 0; c < row.length; c++) {
      final isHeader = s.header && r == 0;
      b.write(_cellXml(r, c, row[c],
          forcedStyle: isHeader ? kStyleHeader : null));
    }
    b.write('</row>');
  }
  b.write('</sheetData>');
  if (s.header && s.rows.length > 1 && cols > 0) {
    b.write('<autoFilter ref="A1:${xlsxColumnName(cols - 1)}${s.rows.length}"/>');
  }
  b.write('</worksheet>');
  return b.toString();
}

const String _stylesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<numFmts count="1"><numFmt numFmtId="164" formatCode="dd/mm/yyyy"/></numFmts>'
    '<fonts count="4">'
    '<font><sz val="11"/><name val="Calibri"/></font>'
    '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>'
    '<font><b/><sz val="15"/><color rgb="FF9E3D66"/><name val="Calibri"/></font>'
    '<font><b/><sz val="11"/><name val="Calibri"/></font>'
    '</fonts>'
    '<fills count="4">'
    '<fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill>'
    '<fill><patternFill patternType="solid"><fgColor rgb="FFC25B85"/><bgColor indexed="64"/></patternFill></fill>'
    '<fill><patternFill patternType="solid"><fgColor rgb="FFFBE4EE"/><bgColor indexed="64"/></patternFill></fill>'
    '</fills>'
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
    '<cellXfs count="6">'
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top"/></xf>'
    '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment horizontal="center" vertical="top"/></xf>'
    '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>'
    '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>'
    '<xf numFmtId="0" fontId="3" fillId="3" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>'
    '</cellXfs>'
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
    '</styleSheet>';

String _safeSheetName(String name, Set<String> used) {
  var n = name.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').trim();
  if (n.isEmpty) n = 'Sheet';
  if (n.length > 31) n = n.substring(0, 31);
  var candidate = n;
  var i = 2;
  while (used.contains(candidate.toLowerCase())) {
    final suffix = ' $i';
    candidate = n.substring(0, math.min(n.length, 31 - suffix.length)) + suffix;
    i++;
  }
  used.add(candidate.toLowerCase());
  return candidate;
}

Uint8List buildXlsx(List<XSheet> sheets) {
  final used = <String>{};
  final names = [for (final s in sheets) _safeSheetName(s.name, used)];

  final contentTypes = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>');
  for (var i = 0; i < sheets.length; i++) {
    contentTypes.write(
        '<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>');
  }
  contentTypes.write(
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '</Types>');

  const rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>';

  final workbook = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<bookViews><workbookView/></bookViews><sheets>');
  final wbRels = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
  for (var i = 0; i < sheets.length; i++) {
    workbook.write(
        '<sheet name="${xlsxEscape(names[i])}" sheetId="${i + 1}" r:id="rId${i + 1}"/>');
    wbRels.write(
        '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>');
  }
  workbook.write('</sheets></workbook>');
  wbRels.write(
      '<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>');

  final files = <String, List<int>>{
    '[Content_Types].xml': utf8.encode(contentTypes.toString()),
    '_rels/.rels': utf8.encode(rootRels),
    'xl/workbook.xml': utf8.encode(workbook.toString()),
    'xl/_rels/workbook.xml.rels': utf8.encode(wbRels.toString()),
    'xl/styles.xml': utf8.encode(_stylesXml),
    for (var i = 0; i < sheets.length; i++)
      'xl/worksheets/sheet${i + 1}.xml': utf8.encode(_sheetXml(sheets[i])),
  };
  return zipStore(files);
}

// ---------------------------------------------------------------- ZIP ----

List<int>? _crcTable;

int crc32(List<int> data) {
  var table = _crcTable;
  if (table == null) {
    table = List<int>.filled(256, 0);
    for (var n = 0; n < 256; n++) {
      var c = n;
      for (var k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
      }
      table[n] = c;
    }
    _crcTable = table;
  }
  var crc = 0xFFFFFFFF;
  for (final b in data) {
    crc = table[(crc ^ b) & 0xFF] ^ (crc >> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

/// Archive ZIP sans compression (methode 0), noms en UTF-8.
Uint8List zipStore(Map<String, List<int>> files) {
  final out = BytesBuilder();
  final central = BytesBuilder();
  var offset = 0;
  var count = 0;
  for (final e in files.entries) {
    final name = utf8.encode(e.key);
    final data = e.value;
    final crc = crc32(data);
    final size = data.length;

    final lh = ByteData(30);
    lh.setUint32(0, 0x04034b50, Endian.little);
    lh.setUint16(4, 20, Endian.little);
    lh.setUint16(6, 0x0800, Endian.little);
    lh.setUint16(8, 0, Endian.little);
    lh.setUint16(10, 0, Endian.little);
    lh.setUint16(12, 0x21, Endian.little);
    lh.setUint32(14, crc, Endian.little);
    lh.setUint32(18, size, Endian.little);
    lh.setUint32(22, size, Endian.little);
    lh.setUint16(26, name.length, Endian.little);
    lh.setUint16(28, 0, Endian.little);
    out.add(lh.buffer.asUint8List());
    out.add(name);
    out.add(data);

    final ch = ByteData(46);
    ch.setUint32(0, 0x02014b50, Endian.little);
    ch.setUint16(4, 20, Endian.little);
    ch.setUint16(6, 20, Endian.little);
    ch.setUint16(8, 0x0800, Endian.little);
    ch.setUint16(10, 0, Endian.little);
    ch.setUint16(12, 0, Endian.little);
    ch.setUint16(14, 0x21, Endian.little);
    ch.setUint32(16, crc, Endian.little);
    ch.setUint32(20, size, Endian.little);
    ch.setUint32(24, size, Endian.little);
    ch.setUint16(28, name.length, Endian.little);
    ch.setUint16(30, 0, Endian.little);
    ch.setUint16(32, 0, Endian.little);
    ch.setUint16(34, 0, Endian.little);
    ch.setUint16(36, 0, Endian.little);
    ch.setUint32(38, 0, Endian.little);
    ch.setUint32(42, offset, Endian.little);
    central.add(ch.buffer.asUint8List());
    central.add(name);

    offset += 30 + name.length + size;
    count++;
  }
  final centralBytes = central.toBytes();
  out.add(centralBytes);

  final end = ByteData(22);
  end.setUint32(0, 0x06054b50, Endian.little);
  end.setUint16(4, 0, Endian.little);
  end.setUint16(6, 0, Endian.little);
  end.setUint16(8, count, Endian.little);
  end.setUint16(10, count, Endian.little);
  end.setUint32(12, centralBytes.length, Endian.little);
  end.setUint32(16, offset, Endian.little);
  end.setUint16(20, 0, Endian.little);
  out.add(end.buffer.asUint8List());
  return out.toBytes();
}
