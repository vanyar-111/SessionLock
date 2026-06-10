import '../lib/evaluation/evaluation.dart';
import '../lib/risk/risk_engine.dart';
import '../lib/risk/ml_risk_engine.dart';

/// SessionLock — ML Anomaly Detection Evaluation
///
/// This script generates a synthetic behavioral dataset of 500 sessions
/// (normal users + impostors), runs both the Classic Rule-Based engine
/// and the ML Z-Score engine against it, and reports Precision, Recall,
/// F1 Score, and Accuracy for each.
///
/// Run with: dart run bin/evaluate.dart

void main() {
  print('');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('  SessionLock — Risk Engine Evaluation Report');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // ── Baseline (the "known" user profile) ──────────────────────────
  final baseline = UserBaseline(
    avgTypingSpeed: 4.0,
    typingSpeedStdDev: 0.5,
    avgTapDuration: 120.0,
    tapDurationStdDev: 15.0,
    commonFirstScreen: 'home',
  );

  // ── Generate Synthetic Dataset ───────────────────────────────────
  final generator = SyntheticDataGenerator(seed: 42);

  final samples = <BehaviorFeatures>[];
  final labels = <bool>[]; // true = attack, false = normal

  // 200 normal sessions
  for (int i = 0; i < 200; i++) {
    samples.add(generator.generateNormalSession(baseline));
    labels.add(false);
  }

  // 200 clear attack sessions
  for (int i = 0; i < 200; i++) {
    samples.add(generator.generateAttackSession(baseline));
    labels.add(true);
  }

  // 100 borderline sessions (labeled as attacks — subtle impostors)
  for (int i = 0; i < 100; i++) {
    samples.add(generator.generateBorderlineSession(baseline));
    labels.add(true);
  }

  print('');
  print('  Dataset: ${samples.length} sessions');
  print('    • 200 normal user sessions');
  print('    • 200 clear attack sessions');
  print('    • 100 borderline/subtle impostor sessions');
  print('');

  // ── Evaluate Classic Rule-Based Engine ───────────────────────────
  final classicEngine = RiskEngine();
  final classicMetrics = evaluateEngine(
    name: 'Classic Rule-Based Engine',
    engine: classicEngine,
    baseline: baseline,
    samples: samples,
    labels: labels,
  );

  // ── Evaluate ML Z-Score Engine ───────────────────────────────────
  final mlEngine = MLRiskEngine();
  final mlMetrics = evaluateEngine(
    name: 'ML Z-Score Anomaly Engine',
    engine: mlEngine,
    baseline: baseline,
    samples: samples,
    labels: labels,
  );

  // ── Print Results ────────────────────────────────────────────────
  print(classicMetrics);
  print('');
  print(mlMetrics);
  print('');

  // ── Side-by-Side Comparison ──────────────────────────────────────
  print('┌──────────────────┬─────────────────┬─────────────────┐');
  print('│ Metric           │ Classic (Rules) │ ML (Z-Score)    │');
  print('├──────────────────┼─────────────────┼─────────────────┤');
  print('│ Accuracy         │ ${_pad(classicMetrics.accuracy)}│ ${_pad(mlMetrics.accuracy)}│');
  print('│ Precision        │ ${_pad(classicMetrics.precision)}│ ${_pad(mlMetrics.precision)}│');
  print('│ Recall           │ ${_pad(classicMetrics.recall)}│ ${_pad(mlMetrics.recall)}│');
  print('│ F1 Score         │ ${_pad(classicMetrics.f1Score)}│ ${_pad(mlMetrics.f1Score)}│');
  print('└──────────────────┴─────────────────┴─────────────────┘');
  print('');
}

String _pad(double value) {
  return '${(value * 100).toStringAsFixed(1)}%'.padRight(16);
}
