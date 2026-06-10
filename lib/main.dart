import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'behavior/behavior_collector.dart';
import 'risk/risk_engine.dart';

final BehaviorCollector behaviorCollector = BehaviorCollector();
final RiskEngine riskEngine = RiskEngine();

// Demo baseline (same as your original)
final UserBaseline demoBaseline = UserBaseline(
  avgTypingSpeed: 4.0,
  avgTapDuration: 120,
  commonFirstScreen: 'home',
);

void main() {
  runApp(const SessionLockApp());
}

class SessionLockApp extends StatelessWidget {
  const SessionLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SessionLock - Behavioral Security',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00C853),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const BehaviorDemoScreen(),
    );
  }
}

class BehaviorDemoScreen extends StatefulWidget {
  const BehaviorDemoScreen({super.key});

  @override
  State<BehaviorDemoScreen> createState() => _BehaviorDemoScreenState();
}

class _BehaviorDemoScreenState extends State<BehaviorDemoScreen> {
  DateTime? _tapStart;
  DateTime? _lastKeyTime;
  RiskResult? _latestRisk;
  final List<String> _eventLog = [];
  Timer? _periodicCheck;

  @override
  void initState() {
    super.initState();
    // Check for risk updates every 2 seconds
    _periodicCheck = Timer.periodic(const Duration(seconds: 2), (_) {
      _evaluateIfWindowReady();
    });
  }

  @override
  void dispose() {
    _periodicCheck?.cancel();
    super.dispose();
  }

  void _evaluateIfWindowReady() {
    final window = behaviorCollector.collectWindowIfReady();
    if (window == null) return;

    final features = BehaviorFeatures(
      avgTypingSpeed: window.typingSpeedKps.toDouble(),
      typingVariance: window.typingVariance.toDouble(),
      avgTapDuration: window.avgTapDurationMs.toDouble(),
      eventsPerWindow: window.eventCount,
      firstScreenAfterLogin: 'home',
    );

    final result = riskEngine.evaluate(
      current: features,
      baseline: demoBaseline,
    );

    setState(() {
      _latestRisk = result;
      _addToLog(
        'Risk evaluated: ${result.level.name.toUpperCase()} (score: ${result.score})',
      );

      if (result.reasons.isNotEmpty) {
        for (final reason in result.reasons) {
          _addToLog('⚠️ $reason');
        }
      }
    });

    if (result.level == RiskLevel.high && mounted) {
      _showHighRiskAlert();
    }
  }

  void _addToLog(String message) {
    final timestamp = TimeOfDay.now().format(context);
    setState(() {
      _eventLog.insert(0, '[$timestamp] $message');
      if (_eventLog.length > 20) _eventLog.removeLast();
    });
  }

  void _showHighRiskAlert() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Text('HIGH RISK DETECTED'),
          ],
        ),
        content: Text(
          _latestRisk?.reasons.join('\n') ?? 'Suspicious behavior detected',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ACKNOWLEDGE',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Simulate normal user behavior
  void _simulateNormalUser() {
    _addToLog('🟢 Simulating NORMAL user behavior...');

    for (int i = 0; i < 8; i++) {
      // Normal typing: ~4 keys/sec, low variance
      behaviorCollector.recordKeyPress(
        timeBetweenKeysMs: 200 + Random().nextInt(50),
      );

      // Normal taps: ~120ms, consistent
      behaviorCollector.recordTap(tapDurationMs: 120 + Random().nextInt(20));
    }

    _addToLog('Generated 8 normal events');
    _evaluateIfWindowReady();
  }

  // Simulate attack/anomalous behavior
  void _simulateAttack() {
    _addToLog('🔴 Simulating ATTACK behavior...');

    for (int i = 0; i < 8; i++) {
      // Fast typing: automated/scripted
      behaviorCollector.recordKeyPress(
        timeBetweenKeysMs: 50 + Random().nextInt(30),
      );

      // Different tap duration: bot-like
      behaviorCollector.recordTap(tapDurationMs: 250 + Random().nextInt(100));
    }

    _addToLog('Generated 8 anomalous events');
    _evaluateIfWindowReady();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return GestureDetector(
      onTapDown: (_) => _tapStart = DateTime.now(),
      onTapUp: (_) {
        if (_tapStart != null) {
          final durationMs = DateTime.now()
              .difference(_tapStart!)
              .inMilliseconds;
          behaviorCollector.recordTap(tapDurationMs: durationMs);
          _addToLog('Tap recorded: ${durationMs}ms');
          _evaluateIfWindowReady();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SessionLock — Behavioral Security Demo'),
          centerTitle: true,
          backgroundColor: const Color(0xFF1E1E1E),
        ),
        body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildMainPanel()),
        Container(width: 1, color: Colors.grey.shade800),
        Expanded(flex: 1, child: _buildEventLog()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(child: _buildMainPanel()),
        Container(height: 200, child: _buildEventLog()),
      ],
    );
  }

  Widget _buildMainPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRiskDisplay(),
          const SizedBox(height: 32),
          _buildSimulationButtons(),
          const SizedBox(height: 32),
          _buildInteractionArea(),
        ],
      ),
    );
  }

  Widget _buildRiskDisplay() {
    final riskScore = _latestRisk?.score ?? 0;
    final riskLevel = _latestRisk?.level ?? RiskLevel.low;
    final riskPercent = (riskScore / 10 * 100).clamp(0, 100).toInt();

    Color riskColor = Colors.green;
    if (riskLevel == RiskLevel.medium) riskColor = Colors.orange;
    if (riskLevel == RiskLevel.high) riskColor = Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Current Risk Level',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: riskPercent / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation(riskColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$riskPercent%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                      Text(
                        riskLevel.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          color: riskColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_latestRisk?.reasons.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ..._latestRisk!.reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: riskColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(reason)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _simulateNormalUser,
            icon: const Icon(Icons.check_circle),
            label: const Text('Simulate Normal User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _simulateAttack,
            icon: const Icon(Icons.bug_report),
            label: const Text('Simulate Attack'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionArea() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual Input (generates real events)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (_) {
                final now = DateTime.now();

                if (_lastKeyTime != null) {
                  final diff = now.difference(_lastKeyTime!).inMilliseconds;
                  behaviorCollector.recordKeyPress(timeBetweenKeysMs: diff);
                  _addToLog('Key press: ${diff}ms interval');
                } else {
                  _addToLog('First key press');
                }

                _lastKeyTime = now;
                _evaluateIfWindowReady();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type here to generate behavioral data...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLog() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
            ),
            child: Row(
              children: [
                const Icon(Icons.article, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Event Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _eventLog.clear()),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _eventLog.isEmpty
                ? const Center(
                    child: Text(
                      'No events yet.\nInteract with the app to generate data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _eventLog.length,
                    itemBuilder: (_, i) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade900),
                        ),
                      ),
                      child: Text(
                        _eventLog[i],
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
