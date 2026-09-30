import 'package:intl/intl.dart';

import '../../data/models/txn.dart';

class DateGrouping {
  /// "Today", "Yesterday", or "Mon, 8 Sep".
  static String dateHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (d.year == now.year) return DateFormat('EEE, d MMM').format(d);
    return DateFormat('d MMM yyyy').format(d);
  }

  /// Groups transactions by calendar day, newest day first.
  static List<MapEntry<DateTime, List<Txn>>> groupByDay(List<Txn> txns) {
    final map = <DateTime, List<Txn>>{};
    for (final t in txns) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(key, () => []).add(t);
    }
    final entries = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }
}
