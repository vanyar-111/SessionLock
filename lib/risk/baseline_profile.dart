class BaselineProfile {
  final String userId;
  final double avgTapDuration;
  final double avgTypingInterval;
  final double interactionRate;

  BaselineProfile({
    required this.userId,
    required this.avgTapDuration,
    required this.avgTypingInterval,
    required this.interactionRate,
  });
}

final baselineUsers = [
  BaselineProfile(
    userId: "UserA",
    avgTapDuration: 125,
    avgTypingInterval: 85,
    interactionRate: 0.8,
  ),
  BaselineProfile(
    userId: "UserB",
    avgTapDuration: 180,
    avgTypingInterval: 120,
    interactionRate: 0.5,
  ),
  BaselineProfile(
    userId: "UserC",
    avgTapDuration: 240,
    avgTypingInterval: 170,
    interactionRate: 0.3,
  ),
];
