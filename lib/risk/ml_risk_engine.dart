import 'risk_engine.dart';

/// An ML-based Risk Engine that uses Gaussian Distribution (Z-Score)
/// Anomaly Detection to evaluate behavioral deviations.
class MLRiskEngine extends RiskEngine {
  
  /// Calculates the Z-Score given a value, mean, and standard deviation.
  /// A higher Z-Score indicates a higher probability of anomaly.
  double _calculateZScore(double value, double mean, double stdDev) {
    if (stdDev == 0) return 0.0;
    return (value - mean).abs() / stdDev;
  }

  @override
  RiskResult evaluate({
    required BehaviorFeatures current,
    required UserBaseline baseline,
  }) {
    int score = 0;
    final reasons = <String>[];

    // 1. Typing Speed Anomaly (Z-Score)
    final typingZScore = _calculateZScore(
      current.avgTypingSpeed,
      baseline.avgTypingSpeed,
      baseline.typingSpeedStdDev,
    );

    // Z-Score > 3 means it's outside the 99.7% confidence interval (Highly Anomalous)
    if (typingZScore > 3.0) {
      score += 2;
      reasons.add("ML Anomaly: Typing speed outside 99.7% confidence interval (Z=$typingZScore)");
    } else if (typingZScore > 2.0) {
      score += 1;
      reasons.add("ML Anomaly: Typing speed outside 95% confidence interval (Z=$typingZScore)");
    }

    // 2. Typing Variance (Unchanged from classic, as we don't have baseline variance for this yet)
    if (current.typingVariance > 2.5) {
      score += 1;
      reasons.add("High typing variance");
    }

    // 3. Tap Duration Anomaly (Z-Score)
    final tapZScore = _calculateZScore(
      current.avgTapDuration,
      baseline.avgTapDuration,
      baseline.tapDurationStdDev,
    );

    if (tapZScore > 3.0) {
      score += 2;
      reasons.add("ML Anomaly: Tap duration outside 99.7% confidence interval (Z=$tapZScore)");
    } else if (tapZScore > 2.0) {
      score += 1;
      reasons.add("ML Anomaly: Tap duration outside 95% confidence interval (Z=$tapZScore)");
    }

    // 4. Interaction Frequency
    if (current.eventsPerWindow < 3) {
      score += 1;
      reasons.add("Low interaction frequency");
    }

    // 5. Navigation Anomaly
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
