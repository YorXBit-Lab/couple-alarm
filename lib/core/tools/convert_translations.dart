import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';

// dart run lib/core/tools/convert_translations.dart
void main() async {
  print('🔄 Converting translations from Excel...\n');

  var excelPath = 'lib/core/tools/translations.xlsx';
  var file = File(excelPath);

  if (!file.existsSync()) {
    print('❌ Error: File not found at $excelPath');
    return;
  }

  print('📖 Reading: $excelPath\n');

  var bytes = file.readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);

  // Lấy sheet đầu tiên
  var sheetName = excel.tables.keys.first;
  var table = excel.tables[sheetName]!;

  print('📊 Sheet: $sheetName');
  print('📏 Rows: ${table.rows.length}\n');

  // Lấy header
  var headers = <String>[];
  for (var cell in table.rows[0]) {
    var value = cell?.value?.toString() ?? '';
    headers.add(value);
  }

  var languages = headers.sublist(1);
  print('📋 Languages: ${languages.join(", ")}\n');

  // Tạo Map cho mỗi ngôn ngữ
  var translations = <String, Map<String, String>>{};
  for (var lang in languages) {
    translations[lang] = {};
  }

  // Lưu tất cả keys để generate class
  var allKeys = <String>[];

  // Đọc dữ liệu
  for (var i = 1; i < table.rows.length; i++) {
    var row = table.rows[i];
    var key = row[0]?.value?.toString().trim() ?? '';

    if (key.isEmpty) continue;

    allKeys.add(key);

    for (var j = 1; j < row.length && j < headers.length; j++) {
      var lang = headers[j];
      var value = row[j]?.value?.toString() ?? '';
      if (value.isNotEmpty) {
        translations[lang]![key] = value;
      }
    }
  }

  // Tạo thư mục translations
  var dir = Directory('assets/translations');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    print('📁 Created: assets/translations/\n');
  }

  translations.forEach((lang, data) {
    var jsonFile = File('assets/translations/$lang.json');

    var jsonString = JsonEncoder.withIndent('  ').convert(data);

    jsonString = jsonString.replaceAll('\\\\n', '\\n');

    jsonFile.writeAsStringSync(jsonString);
    print('✅ Created: $lang.json (${data.length} keys)');
  });

  _generateTranslationKeysClass(allKeys);
}

void _generateTranslationKeysClass(List<String> keys) {
  var buffer = StringBuffer();

  buffer.writeln('class TransKeys {');
  buffer.writeln('  TransKeys._();\n');

  var sortedKeys = List<String>.from(keys)..sort();

  for (var key in sortedKeys) {
    var fieldName = _toValidDartIdentifier(key);
    buffer.writeln("  static const String $fieldName = '$key';");
  }

  buffer.writeln('}');

  var dir = Directory('lib/core/constants');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  var outputFile = File('lib/core/constants/trans_keys.dart');
  outputFile.writeAsStringSync(buffer.toString());

  print('✅ Generated: trans_keys.dart (${keys.length} keys)');
}

String _toValidDartIdentifier(String key) {
  // Chỉ làm sạch ký tự không hợp lệ, giữ nguyên format camelCase từ Excel
  var cleaned = key
      .replaceAll(RegExp(r'[^\w]'), '_') // Thay ký tự đặc biệt bằng _
      .replaceAll(RegExp(r'_+'), '_') // Gộp nhiều _ thành 1
      .replaceAll(RegExp(r'^_+|_+$'), ''); // Xóa _ đầu cuối

  // Nếu bắt đầu bằng số, thêm prefix
  if (cleaned.isNotEmpty && RegExp(r'^\d').hasMatch(cleaned)) {
    cleaned = 'k$cleaned';
  }

  // Nếu rỗng hoặc là keyword của Dart
  if (cleaned.isEmpty || _isDartKeyword(cleaned)) {
    cleaned = 'k${key.hashCode.abs()}';
  }

  return cleaned;
}

bool _isDartKeyword(String name) {
  const keywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'default',
    'do',
    'else',
    'enum',
    'extends',
    'false',
    'final',
    'finally',
    'for',
    'if',
    'in',
    'is',
    'new',
    'null',
    'return',
    'super',
    'switch',
    'this',
    'throw',
    'true',
    'try',
    'var',
    'void',
    'while',
    'with',
  };
  return keywords.contains(name);
}
