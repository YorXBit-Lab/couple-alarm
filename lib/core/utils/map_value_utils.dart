import 'package:cloud_firestore/cloud_firestore.dart';

/// Utils chuyển đổi kiểu dữ liệu an toàn (Firestore-friendly).
/// - Không throw với input "bẩn"
/// - Hỗ trợ Timestamp/DateTime/epoch/string
/// - Chuẩn hoá rỗng/`"null"`/`"undefined"`
/// - Có cả bản extension cho Map<String,dynamic> để gọi gọn hơn
class ValueUtils {
  /// Trả về String (fallback nếu null/blank).
  static String asString(
    dynamic v, {
    String fallback = '',
    bool nullLikeIsBlank = true, // "null", "undefined" => blank
  }) {
    if (v == null) return fallback;
    final s = v.toString();
    if (nullLikeIsBlank && _isBlankish(s)) return fallback;
    return s;
  }

  /// Trả về String? (null nếu null/blank/"null"/"undefined").
  static String? asStringOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (_isBlankish(s)) return null;
    return s;
  }

  /// Chuyển List hoặc "a,b,c" => List<String>? (lọc rỗng, unique, có thể custom separator).
  static List<String>? toStringListOrNull(
    dynamic v, {
    String? separator,
    bool unique = true,
    bool skipEmpty = true,
    bool trimEach = true,
  }) {
    List<String> out = [];

    if (v == null) return null;

    if (v is List) {
      for (final e in v) {
        final s = asStringOrNull(e);
        if (s == null) continue;
        out.add(trimEach ? s.trim() : s);
      }
    } else if (v is String) {
      final raw = v;
      final parts = (separator == null) ? raw.split(',') : raw.split(separator);
      for (final p in parts) {
        final s = trimEach ? p.trim() : p;
        if (skipEmpty && _isBlankish(s)) continue;
        out.add(s);
      }
    } else {
      // các kiểu khác -> toString()
      final s = asStringOrNull(v);
      if (s != null) out.add(trimEach ? s.trim() : s);
    }

    if (skipEmpty) {
      out = out.where((e) => !_isBlankish(e)).toList();
    }
    if (unique) {
      out = out.toSet().toList();
    }
    return out.isEmpty ? null : out;
  }

  /// Chuyển dynamic => DateTime?
  /// - Timestamp (Firestore)
  /// - DateTime
  /// - num: tự nhận biết seconds/millis
  /// - String: ISO 8601 / RFC 3339 (DateTime.tryParse)
  static DateTime? toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) {
      final s = v.trim();
      if (_isBlankish(s)) return null;
      return DateTime.tryParse(s);
    }
    if (v is num) {
      final n = v.toDouble();
      // Heuristics: > 1e12 ~ millis, > 1e9 ~ seconds
      if (n > 1e12) return DateTime.fromMillisecondsSinceEpoch(n.toInt());
      if (n > 1e9)
        return DateTime.fromMillisecondsSinceEpoch((n * 1000).toInt());
      return DateTime.fromMillisecondsSinceEpoch(n.toInt());
    }
    return null;
  }

  /// Bool "mềm": true/false, 1/0, yes/no, y/n, on/off (case-insensitive).
  static bool asBool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (s.isEmpty) return fallback;
    if (<String>{'true', '1', 'yes', 'y', 'on'}.contains(s)) return true;
    if (<String>{'false', '0', 'no', 'n', 'off'}.contains(s)) return false;
    return fallback;
  }

  /// Parse enum an toàn: trả fallback nếu lỗi/raw null.
  /// - [parser] là hàm từ String -> enum T (vd: ApprovalStatus.fromString).
  /// - [synonyms] map synonyms -> canonical (vd: {'ok':'done','completed':'done'}).
  static T parseEnumOr<T>(
    String? raw,
    T Function(String) parser,
    T fallback, {
    bool caseInsensitive = true,
    Map<String, String>? synonyms,
  }) {
    if (raw == null || _isBlankish(raw)) return fallback;
    var s = raw.trim();
    if (caseInsensitive) s = s.toLowerCase();

    if (synonyms != null && synonyms.isNotEmpty) {
      final map = caseInsensitive
          ? {for (final e in synonyms.entries) e.key.toLowerCase(): e.value}
          : synonyms;
      if (map.containsKey(s)) s = map[s]!;
    }

    try {
      return parser(s);
    } catch (_) {
      return fallback;
    }
  }

  /// Xoá key có value = null (để ghi Firestore sạch sẽ).
  static Map<String, dynamic> compactMap(Map<String, dynamic> input) {
    final out = Map<String, dynamic>.from(input);
    out.removeWhere((_, v) => v == null);
    return out;
  }

  static bool _isBlankish(String s) {
    final t = s.trim().toLowerCase();
    return t.isEmpty || t == 'null' || t == 'undefined';
  }
}

/// Extension cho Map<String, dynamic> để đọc ngắn gọn hơn.
extension MapValueX on Map<String, dynamic> {
  String getString(String key, {String fallback = ''}) =>
      ValueUtils.asString(this[key], fallback: fallback);

  String? getStringOrNull(String key) => ValueUtils.asStringOrNull(this[key]);

  List<String>? getStringList(
    String key, {
    String? separator,
    bool unique = true,
    bool skipEmpty = true,
    bool trimEach = true,
  }) => ValueUtils.toStringListOrNull(
    this[key],
    separator: separator,
    unique: unique,
    skipEmpty: skipEmpty,
    trimEach: trimEach,
  );

  DateTime? getDateTime(String key) => ValueUtils.toDateTime(this[key]);

  bool getBool(String key, {bool fallback = false}) =>
      ValueUtils.asBool(this[key], fallback: fallback);

  /// Lấy string đầu tiên khác null/rỗng trong danh sách keys (alias).
  String getStringIn(List<String> keys, {String fallback = ''}) {
    for (final k in keys) {
      final s = getStringOrNull(k);
      if (s != null) return s;
    }
    return fallback;
  }

  String? getStringInOrNull(List<String> keys) {
    for (final k in keys) {
      final s = getStringOrNull(k);
      if (s != null) return s;
    }
    return null;
  }

  /// Kiểm tra key tồn tại & không rỗng.
  bool hasNonEmpty(String key) {
    final v = this[key];
    final s = ValueUtils.asStringOrNull(v);
    return s != null && s.isNotEmpty;
  }
}
