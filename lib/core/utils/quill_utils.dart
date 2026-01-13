import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

class QuillUtils {
  static Document safeParseNoteContent(String content) {
    try {
      final jsonData = jsonDecode(content);
      if (jsonData is List) {
        return Document.fromJson(jsonData);
      } else {
        throw FormatException('Not a valid delta JSON');
      }
    } catch (e) {
      return Document()..insert(0, content);
    }
  }
}
