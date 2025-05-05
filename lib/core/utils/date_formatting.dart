import 'package:intl/intl.dart';

String formatMeetingDateTime(DateTime dateTime) {
  final DateFormat formatter = DateFormat(
    'MMM d,EEEE • h:mm a',
  ); // Added EEEE for day of the week
  return formatter.format(dateTime.toLocal());
}

String formatMeetingDuration(DateTime startTime, DateTime? endTime) {
  if (endTime == null) return 'Ongoing';
  final diff = endTime.difference(startTime);
  if (diff.inHours > 0) {
    return '${diff.inHours} hr ${diff.inMinutes.remainder(60)} min';
  } else if (diff.inMinutes > 0) {
    return '${diff.inMinutes} min ${diff.inSeconds.remainder(60)} sec';
  } else if (diff.inSeconds > 0) {
    return '${diff.inSeconds} sec';
  } else {
    return 'Less than a second';
  }
}
