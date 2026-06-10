# SessionLock

**SessionLock** — Behavior-based Continuous Authentication (Architecture Prototype)

SessionLock is an **architecture-focused prototype** for behavior-based continuous authentication in mobile applications. Instead of relying on static credentials (Passwords, OTPs, biometrics) it models user interaction behavior and evaluates risk continuously during a session.

This repository intentionally focuses on event collection, risk scoring and adaptive decision logic, not on building a production-ready mobile app.

## Problem Statement
Traditional authentication mechanisms have clear weaknesses: 
- Passwords and OTPs can be shared, phished or replayed.
- Biometrics are static and only verified at login.
- Authentication is usually binary (pass/fail), not continuous.

SessionLock explores the idea of continuous authentication.

## Core Idea
Every user interacts with an app in a unique way. SessionLock continuously observes interaction patterns and compares them against expected behavior to assign a real-time risk score.

### Examples of behavioral signals:
- Tap Duration
- Typing rhythm (time between key presses)
- Interaction frequency 
- Screen-level activity context

These signals are hard to replicate, even if credentials are compromised.

## Architecture Overview

```
User Interaction
      ↓
Behavior Collector (captures raw events)
      ↓
ML Risk Engine (Z-Score anomaly detection)
      ↓
Risk Result:
     Low  → Silent Continuation
     Medium → Verification Prompt
     High → Session Termination
```

This flow is event-driven and intentionally decoupled:
- No UI logic inside risk evaluation 
- No platform-specific dependencies
- Deterministic, explainable decisions

## ML-Based Anomaly Detection

SessionLock uses **Gaussian Distribution (Z-Score) Anomaly Detection** instead of hard-coded static thresholds to evaluate behavioral risk.

### How it works:
1. A **baseline profile** is established with the user's average behavior and its standard deviation (e.g., average typing speed = 4.0 KPS ± 0.5).
2. When new behavioral data arrives, the engine computes the **Z-Score** — how many standard deviations the current behavior is from the user's normal.
3. Risk is assigned based on statistical confidence intervals:
   - **Z > 3.0** (outside 99.7% confidence) → High anomaly score
   - **Z > 2.0** (outside 95% confidence) → Moderate anomaly score
   - **Z ≤ 2.0** → Normal behavior

This approach is mathematically robust and adapts to each user's unique interaction patterns.

## Repository Structure
```
lib/
├── behavior/
│   └── behavior_collector.dart   // Collects interaction events
├── risk/
│   ├── risk_engine.dart          // Core risk evaluation logic & data models
│   ├── ml_risk_engine.dart       // ML-based Z-Score anomaly detection engine
│   ├── risk_result.dart          // Risk levels & explanations
│   └── baseline_profile.dart     // User baseline profiles with std deviations
└── main.dart                     // Demo app wiring behavior → risk
```

## Scope Disclaimer

This project is not:
- A full banking application
- A production-ready authentication system
- A UI-focused Flutter app

This project is:
- An architectural prototype
- A demonstration of behavioral security thinking
- A foundation for future adaptive authentication systems

## What This Demonstrates Technically

- Event-driven system design
- Behavioral modeling without raw biometrics
- ML-based risk scoring using Z-Score anomaly detection
- Statistical confidence intervals for decision making
- Separation of concerns (collection vs evaluation vs response)
- Security-oriented product thinking

## Future Extensions (Out of Scope for This Repo)

- On-device model training
- Backend-assisted session analytics
- Privacy-preserving behavioral baselines (Federated Learning)

These are deliberately excluded to keep the prototype focused and auditable.
