enum RiskLevel { low, medium, high }

class UserBaseline {
  final double avgTypingSpeed;
  final double typingSpeedStdDev;
  final double avgTapDuration;
  final double tapDurationStdDev;
  final String commonFirstScreen;

  const UserBaseline({
    required this.avgTypingSpeed,
    required this.typingSpeedStdDev,
    required this.avgTapDuration,
    required this.tapDurationStdDev,
    required this.commonFirstScreen,
  });
}

class BehaviorFeatures {
  final double avgTypingSpeed;
  final double typingVariance;
  final double avgTapDuration;
  final int eventsPerWindow;
  final String firstScreenAfterLogin;

  BehaviorFeatures({
    required this.avgTypingSpeed,
    required this.typingVariance,
    required this.avgTapDuration,
    required this.eventsPerWindow,
    required this.firstScreenAfterLogin,
  });
}

class RiskResult {
  final RiskLevel level;
  final int score;
  final List<String> reasons;

  const RiskResult({
    required this.level,
    required this.score,
    required this.reasons,
  });
}

class RiskEngine {
  RiskResult evaluate({
    required BehaviorFeatures current,
    required UserBaseline baseline,
  }) {
    int score = 0;
    final reasons = <String>[];

    // Typing Speed Deviation
    final typingDeviation = (current.avgTypingSpeed - baseline.avgTypingSpeed)
        .abs();

    if (typingDeviation > 2) {
      score += 2;
      reasons.add("Large typing speed deviation");
    } else if (typingDeviation > 1) {
      score += 1;
      reasons.add("Moderate typing speed deviation");
    }

    // Typing Variance
    if (current.typingVariance > 2.5) {
      score += 1;
      reasons.add("High typing variance");
    }

    // Tap Duration Deviation
    final tapDeviation = (current.avgTapDuration - baseline.avgTapDuration)
        .abs();

    if (tapDeviation > 80) {
      score += 2;
      reasons.add("Large tap duration deviation");
    } else if (tapDeviation > 40) {
      score += 1;
      reasons.add("Moderate tap duration deviation");
    }

    // Interaction Frequency
    if (current.eventsPerWindow < 3) {
      score += 1;
      reasons.add("Low interaction frequency");
    }

    // Navigation Anomaly
    if (current.firstScreenAfterLogin != baseline.commonFirstScreen) {
      score += 2;
      reasons.add("Unexpected navigation flow after login");
    }

    final RiskLevel level = score >= 5
        ? RiskLevel.high
        : score >= 2
        ? RiskLevel.medium
        : RiskLevel.low;

    return RiskResult(level: level, score: score, reasons: reasons);
  }
}
