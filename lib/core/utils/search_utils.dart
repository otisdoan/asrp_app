import 'dart:math' show cos, sqrt, asin;

class SearchUtils {
  /// Loại bỏ toàn bộ dấu tiếng Việt khỏi chuỗi văn bản
  static String removeVietnameseDiacritics(String text) {
    if (text.isEmpty) return text;
    const vietnamese = 'aAeEoOuUiIdDyY';
    final vietnameseRegex = <RegExp>[
      RegExp(r'à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ'),
      RegExp(r'À|Á|Ạ|Ả|Ã|Â|Ầ|Ấ|Ậ|Ẩ|Ẫ|Ă|Ằ|Ắ|Ặ|Ẳ|Ẵ'),
      RegExp(r'è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ'),
      RegExp(r'È|É|Ẹ|Ẻ|Ẽ|Ê|Ề|Ế|Ệ|Ể|Ễ'),
      RegExp(r'ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ'),
      RegExp(r'Ò|Ó|Ọ|Ỏ|Õ|Ô|Ồ|Ố|Ộ|Ổ|Ỗ|Ơ|Ờ|Ớ|Ợ|Ở|Ỡ'),
      RegExp(r'ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ'),
      RegExp(r'Ù|Ú|Ụ|Ủ|Ũ|Ư|Ừ|Ứ|Ự|Ử|Ữ'),
      RegExp(r'ì|í|ị|ỉ|ĩ'),
      RegExp(r'Ì|Í|Ị|Ỉ|Ĩ'),
      RegExp(r'đ'),
      RegExp(r'Đ'),
      RegExp(r'ỳ|ý|ỵ|ỷ|ỹ'),
      RegExp(r'Ỳ|Ý|Ỵ|Ỷ|Ỹ')
    ];

    var result = text;
    for (var i = 0; i < vietnamese.length; ++i) {
      result = result.replaceAll(vietnameseRegex[i], vietnamese[i]);
    }
    return result;
  }

  /// Kiểm tra khớp từ khóa chính xác (Strict Word Boundary Match).
  /// Ví dụ: "pho" sẽ khớp "pho bo", "pho ga" nhưng không khớp "phong" hay "che".
  static bool isStrictQueryMatch(String query, String targetName) {
    if (query.trim().isEmpty || targetName.trim().isEmpty) return false;
    final normalizedQuery = removeVietnameseDiacritics(query).toLowerCase().trim();
    final normalizedTarget = removeVietnameseDiacritics(targetName).toLowerCase();

    // Check direct substring inclusion for short terms or regex word boundary match
    final queryWords = normalizedQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    for (final word in queryWords) {
      if (word.length <= 2) {
        if (!normalizedTarget.contains(word)) return false;
      } else {
        final regex = RegExp(r'\b' + RegExp.escape(word) + r'\b');
        if (!regex.hasMatch(normalizedTarget) && !normalizedTarget.contains(word)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Tính khoảng cách đường chim bay giữa 2 tọa độ GPS (km) theo Haversine Formula
  static double calculateDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    const c = cos;
    final a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
