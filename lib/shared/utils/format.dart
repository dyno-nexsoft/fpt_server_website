/// Compact duration formatting matching the wireframe's `12s` / `4 min` /
/// `2h 10m` style.
String formatDuration(Duration duration) {
  if (duration.inSeconds < 60) return '${duration.inSeconds}s';
  if (duration.inMinutes < 60) {
    final seconds = duration.inSeconds % 60;
    return seconds == 0
        ? '${duration.inMinutes} min'
        : '${duration.inMinutes}.${(seconds / 60 * 10).round()} min';
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
}

/// Relative-day timestamp: `10:00:12` for today, `yesterday`, else a date.
String formatRelativeTimestamp(DateTime dateTime) {
  final local = dateTime.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diffDays = today.difference(day).inDays;

  String two(int n) => n.toString().padLeft(2, '0');
  final time = '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';

  if (diffDays == 0) return time;
  if (diffDays == 1) return 'yesterday';
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}

String formatUptime(int uptimeSeconds) =>
    formatDuration(Duration(seconds: uptimeSeconds));
