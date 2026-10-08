import 'package:intl/intl.dart';

String formatDate(dynamic date) {
  if (date == null) return '-';
  DateTime dt;
  if (date is DateTime) {
    dt = date;
  } else if (date is String) {
    dt = DateTime.tryParse(date) ?? DateTime.now();
  } else {
    return '-';
  }
  return DateFormat('d MMM yyyy', 'id_ID').format(dt);
}

String formatFullDate(DateTime date) {
  return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
}

String formatMonthYear(DateTime date) {
  return DateFormat('MMMM yyyy', 'id_ID').format(date);
}
