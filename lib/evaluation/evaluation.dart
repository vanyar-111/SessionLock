import 'dart:math';
import '../risk/risk_engine.dart';
import '../risk/ml_risk_engine.dart';

/// Generates synthetic behavioral sessions for evaluation.
/// Each session is labeled as either 'normal' (legitimate user) or 'attack' (impostor).
class SyntheticDataGenerator {
  final Random _rng;

  SyntheticDataGenerator({int? seed}) : _rng = Random(seed ?? 42);

  /// Generates a normal user session — behavior close to baseline with small noise.
  BehaviorFeatures generateNormalSession(UserBaseline baseline) {
    return BehaviorFeatures(
      avgTypingSpeed: baseline.avgTypingSpeed + _gaussian() * baseline.typingSpeedStdDev * 0.8,
      typingVariance: 0.5 + _rng.nextDouble() * 1.5, // low variance (0.5–2.0)
      avgTapDuration: baseline.avgTapDuration + _gaussian() * baseline.tapDurationStdDev * 0.8,
      eventsPerWindow: 5 + _rng.nextInt(10), // healthy activity (5–14)
      firstScreenAfterLogin: baseline.commonFirstScreen,
    );
  }

  /// Generates an attack/impostor session — behavior significantly different from baseline.
  BehaviorFeatures generateAttackSession(UserBaseline baseline) {
    // Attackers deviate 4–8 standard deviations from normal
    final typingShift = (4.0 + _rng.nextDouble() * 4.0) * baseline.typingSpeedStdDev;
    final tapShift = (4.0 + _rng.nextDouble() * 4.0) * baseline.tapDurationStdDev;

    return BehaviorFeatures(
      avgTypingSpeed: baseline.avgTypingSpeed + (_rng.nextBool() ? typingShift : -typingShift),
      typingVariance: 2.5 + _rng.nextDouble() * 3.0, // high variance (2.5–5.5)
      avgTapDuration: baseline.avgTapDuration + (_rng.nextBool() ? tapShift : -tapShift),
      eventsPerWindow: 1 + _rng.nextInt(3), // low activity (1–3)
      firstScreenAfterLogin: _rng.nextBool() ? 'settings' : 'transfer', // unexpected nav
    );
  }

  /// Generates a borderline/ambiguous session — slightly outside normal range.
  /// These are the hardest cases for any detector.
  BehaviorFeatures generateBorderlineSession(UserBaseline baseline) {
    final typingShift = (1.5 + _rng.nextDouble() * 1.5) * baseline.typingSpeedStdDev;
    final tapShift = (1.5 + _rng.nextDouble() * 1.5) * baseline.tapDurationStdDev;

    return BehaviorFeatures(
      avgTypingSpeed: baseline.avgTypingSpeed + (_rng.nextBool() ? typingShift : -typingShift),
      typingVariance: 1.5 + _rng.nextDouble() * 1.5,
      avgTapDuration: baseline.avgTapDuration + (_rng.nextBool() ? tapShift : -tapShift),
      eventsPerWindow: 3 + _rng.nextInt(4),
      firstScreenAfterLogin: baseline.commonFirstScreen,
    );
  }

  /// Box-Muller transform: generates a sample from a standard normal distribution.
  double _gaussian() {
    final u1 = _rng.nextDouble();
    final u2 = _rng.nextDouble();
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
  }
}

/// Holds the results of a binary classification evaluation.
class EvaluationMetrics {
  final String engineName;
  final int truePositives;
  final int falsePositives;
  final int trueNegatives;
  final int falseNegatives;

  EvaluationMetrics({
    required this.engineName,
    required this.truePositives,
    required this.falsePositives,
    required this.trueNegatives,
    required this.falseNegatives,
  });

  int get totalSamples => truePositives + falsePositives + trueNegatives + falseNegatives;
  double get accuracy => totalSamples == 0 ? 0 : (truePositives + trueNegatives) / totalSamples;
  double get precision => (truePositives + falsePositives) == 0 ? 0 : truePositives / (truePositives + falsePositives);
  double get recall => (truePositives + falseNegatives) == 0 ? 0 : truePositives / (truePositives + falseNegatives);
  double get f1Score => (precision + recall) == 0 ? 0 : 2 * (precision * recall) / (precision + recall);

  @override
  String toString() {
    return '''
╔══════════════════════════════════════════════════╗
║  $engineName
╠══════════════════════════════════════════════════╣
║  Total Samples  : $totalSamples
║  True Positives : $truePositives
║  False Positives: $falsePositives
║  True Negatives : $trueNegatives
║  False Negatives: $falseNegatives
╠──────────────────────────────────────────────────╣
║  Accuracy  : ${(accuracy * 100).toStringAsFixed(1)}%
║  Precision : ${(precision * 100).toStringAsFixed(1)}%
║  Recall    : ${(recall * 100).toStringAsFixed(1)}%
║  F1 Score  : ${(f1Score * 100).toStringAsFixed(1)}%
╚══════════════════════════════════════════════════╝''';
  }
}

/// Evaluates a RiskEngine against a labeled dataset.
EvaluationMetrics evaluateEngine({
  required String name,
  required RiskEngine engine,
  required UserBaseline baseline,
  required List<BehaviorFeatures> samples,
  required List<bool> labels, // true = attack, false = normal
}) {
  int tp = 0, fp = 0, tn = 0, fn = 0;

  for (int i = 0; i < samples.length; i++) {
    final result = engine.evaluate(current: samples[i], baseline: baseline);
    final predictedAttack = result.level == RiskLevel.medium || result.level == RiskLevel.high;
    final actualAttack = labels[i];

    if (predictedAttack && actualAttack) {
      tp++;
    } else if (predictedAttack && !actualAttack) {
      fp++;
    } else if (!predictedAttack && !actualAttack) {
      tn++;
    } else {
      fn++;
    }
  }

  return EvaluationMetrics(
    engineName: name,
    truePositives: tp,
    falsePositives: fp,
    trueNegatives: tn,
    falseNegatives: fn,
  );
}
