import 'package:intl/intl.dart';

/// Compact duration formatting matching the wireframe's `12s` / `4 min 12s` /
/// `2h 10m` style.
String formatDuration(Duration duration) {
  if (duration.inSeconds < 60) return '${duration.inSeconds}s';
  if (duration.inMinutes < 60) {
    final seconds = duration.inSeconds % 60;
    return seconds == 0
        ? '${duration.inMinutes} min'
        : '${duration.inMinutes} min ${seconds}s';
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
}

/// Relative timestamp: `just now` / `5m ago` / `3h ago` for anything within
/// the last day, then `yesterday`, a weekday name for the last week, and a
/// full date beyond that — the scannable "how stale is this" a dashboard
/// list needs, rather than an exact clock time nobody's doing math on.
String formatRelativeTimestamp(DateTime dateTime) {
  final local = dateTime.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);

  if (diff.inSeconds < 5) return 'just now';
  if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';

  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diffDays = today.difference(day).inDays;

  if (diffDays == 1) return 'yesterday';
  if (diffDays < 7) return DateFormat.EEEE().format(local);
  return DateFormat('yyyy-MM-dd').format(local);
}

String formatUptime(int uptimeSeconds) =>
    formatDuration(Duration(seconds: uptimeSeconds));

/// `Platform.version` reads like `3.12.2 (stable) (Tue Jun 9 01:11:39 2026
/// -0700) on "macos_arm64"` — useful in a diagnostics dump, not in a sidebar
/// tile. Keeps just the leading semver.
String formatDartVersion(String platformVersion) =>
    platformVersion.split(' ').first;

final _fileSizeFormat = NumberFormat('0.0');

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${_fileSizeFormat.format(bytes / 1024)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${_fileSizeFormat.format(bytes / (1024 * 1024))} MB';
  }
  return '${_fileSizeFormat.format(bytes / (1024 * 1024 * 1024))} GB';
}
