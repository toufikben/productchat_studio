/// VoiceSearchService — يبحث في السجل عن طريق الأوامر الصوتية.
class VoiceSearchService {
  /// يحوّل نص البحث الصوتي إلى مرشحات.
  SearchFilters parseQuery(String query) {
    final q = query.toLowerCase();

    // ─── Filter by operation ───
    EditOp? op;
    if (q.contains('background') || q.contains('خلفية')) op = EditOp.removeBg;
    else if (q.contains('enhance') || q.contains('تحسين')) op = EditOp.enhance;
    else if (q.contains('shadow') || q.contains('ظل')) op = EditOp.shadow;
    else if (q.contains('relight') || q.contains('إضاءة')) op = EditOp.relight;
    else if (q.contains('colorize') || q.contains('تلوين')) op = EditOp.colorize;
    else if (q.contains('inpaint') || q.contains('إزالة')) op = EditOp.inpaint;
    else if (q.contains('export') || q.contains('تصدير')) op = EditOp.export;

    // ─── Filter by time ───
    DateTimeRange? range;
    final now = DateTime.now();
    if (q.contains('today') || q.contains('اليوم')) {
      final start = DateTime(now.year, now.month, now.day);
      range = DateTimeRange(start, now);
    } else if (q.contains('yesterday') || q.contains('أمس')) {
      final start = DateTime(now.year, now.month, now.day - 1);
      final end = DateTime(now.year, now.month, now.day);
      range = DateTimeRange(start, end);
    } else if (q.contains('week') || q.contains('أسبوع')) {
      range = DateTimeRange(now.subtract(const Duration(days: 7)), now);
    } else if (q.contains('month') || q.contains('شهر')) {
      range = DateTimeRange(now.subtract(const Duration(days: 30)), now);
    }

    return SearchFilters(operation: op, timeRange: range);
  }

  /// يبحث في قائمة السجل.
  List<Map<String, dynamic>> search(
    List<Map<String, dynamic>> history,
    String query,
  ) {
    final filters = parseQuery(query);

    return history.where((item) {
      // Filter by op
      if (filters.operation != null) {
        final opName = item['op'] as String? ?? '';
        if (opName != filters.operation!.name) return false;
      }

      // Filter by time
      if (filters.timeRange != null) {
        final ts = DateTime.tryParse(item['ts'] as String? ?? '');
        if (ts == null) return false;
        if (ts.isBefore(filters.timeRange!.start)) return false;
        if (ts.isAfter(filters.timeRange!.end)) return false;
      }

      return true;
    }).toList();
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  const DateTimeRange(this.start, this.end);
}

class SearchFilters {
  final EditOp? operation;
  final DateTimeRange? timeRange;
  const SearchFilters({this.operation, this.timeRange});
}
