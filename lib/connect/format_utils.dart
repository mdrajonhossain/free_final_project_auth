import 'package:intl/intl.dart';

class FormatUtils {
  /// Removes HTML tags and entities from a string
  static String stripHtml(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
  }

  /// Formats an ISO8601 string to 'h:mm a' (e.g., 10:30 AM)
  static String formatTime(String? dateTime) {
    try {
      if (dateTime == null || dateTime.isEmpty) {
        return "";
      }
      final date = DateTime.parse(dateTime).toLocal();
      return DateFormat('h:mm a').format(date);
    } catch (e) {
      return "";
    }
  }
}
