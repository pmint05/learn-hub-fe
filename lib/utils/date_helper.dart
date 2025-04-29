
import 'package:intl/intl.dart';

class DateHelper {
  static DateTime utcStringToLocal(String utcString) {
    final utcDateTime = DateFormat(
      'yyyy-MM-ddTHH:mm:ssZ',
    ).parse(utcString, true);
    return utcDateTime.toLocal();
  }
}