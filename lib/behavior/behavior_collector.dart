// lib/behavior/behavior_collector.dart

class BehaviorWindow {
  final num typingSpeedKps; // keys per second
  final double typingVariance;
  final double avgTapDurationMs;
  final int eventCount;

  const BehaviorWindow({
    required this.typingSpeedKps,
    required this.typingVariance,
    required this.avgTapDurationMs,
    required this.eventCount,
  });
}

class BehaviorCollector {
  // --- Configuration ---
  static const int windowSeconds = 10;

  // --- Internal state ---
  final List<int> _keyIntervalsMs = [];
  int _tapCount = 0;
  int _totalTapDurationMs = 0;
  int _eventCount = 0;
  DateTime _windowStart = DateTime.now();

  // --- Called when user types ---
  void recordKeyPress({required int timeBetweenKeysMs}) {
    _keyIntervalsMs.add(timeBetweenKeysMs);
    _eventCount++;
  }

  // --- Called when user taps ---
  void recordTap({required int tapDurationMs}) {
    _tapCount++;
    _totalTapDurationMs += tapDurationMs;
    _eventCount++;
  }

  /// Returns a BehaviorWindow every [windowSeconds], otherwise null
  BehaviorWindow? collectWindowIfReady() {
    final now = DateTime.now();
    final elapsed = now.difference(_windowStart).inSeconds;

    if (elapsed < windowSeconds) return null;

    final typingSpeedKps = _keyIntervalsMs.isEmpty
        ? 0
        : _keyIntervalsMs.length / elapsed;

    final variance = _calculateVariance(_keyIntervalsMs);

    final avgTapDuration = _tapCount == 0 ? 0 : _totalTapDurationMs / _tapCount;

    final snapshot = BehaviorWindow(
      typingSpeedKps: typingSpeedKps,
      typingVariance: variance,
      avgTapDurationMs: avgTapDuration.toDouble(),
      eventCount: _eventCount,
    );

    _resetWindow();
    return snapshot;
  }

  // --- Helpers ---
  double _calculateVariance(List<int> values) {
    if (values.length < 2) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;

    final squaredDiffs = values
        .map((v) => (v - mean) * (v - mean))
        .reduce((a, b) => a + b);

    return squaredDiffs / values.length;
  }

  void _resetWindow() {
    _keyIntervalsMs.clear();
    _tapCount = 0;
    _totalTapDurationMs = 0;
    _eventCount = 0;
    _windowStart = DateTime.now();
  }
}
