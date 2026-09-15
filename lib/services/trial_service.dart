import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TrialState {
  final bool isActive;
  final bool hasUsedTrial;
  final DateTime? startedAt;
  final int daysRemaining;

  const TrialState({
    this.isActive = false,
    this.hasUsedTrial = false,
    this.startedAt,
    this.daysRemaining = 0,
  });

  TrialState copyWith({
    bool? isActive,
    bool? hasUsedTrial,
    DateTime? startedAt,
    int? daysRemaining,
  }) =>
      TrialState(
        isActive: isActive ?? this.isActive,
        hasUsedTrial: hasUsedTrial ?? this.hasUsedTrial,
        startedAt: startedAt ?? this.startedAt,
        daysRemaining: daysRemaining ?? this.daysRemaining,
      );
}

/// TrialService — 7 أيام Pro مجانية للمستخدم الجديد.
class TrialService extends StateNotifier<TrialState> {
  TrialService() : super(const TrialState()) {
    _load();
  }

  static const _kStarted = 'trial_started';
  static const _kUsed = 'trial_used';
  static const _trialDays = 7;

  void _load() {
    final box = Hive.box('settings');
    final hasUsed = box.get(_kUsed, defaultValue: false) as bool;
    final startedStr = box.get(_kStarted) as String?;

    if (!hasUsed || startedStr == null) {
      state = TrialState(hasUsedTrial: hasUsed);
      return;
    }

    final started = DateTime.parse(startedStr);
    final now = DateTime.now();
    final elapsed = now.difference(started).inDays;
    final remaining = (_trialDays - elapsed).clamp(0, _trialDays);

    state = TrialState(
      isActive: remaining > 0,
      hasUsedTrial: true,
      startedAt: started,
      daysRemaining: remaining,
    );
  }

  /// بدء التجربة (يُستدعى من Splash لأول مرة).
  Future<void> startTrial() async {
    if (state.hasUsedTrial) return;

    final box = Hive.box('settings');
    final now = DateTime.now();
    await box.put(_kStarted, now.toIso8601String());
    await box.put(_kUsed, true);
    await box.put('isPro', true);
    await box.put('proExpiry', now.add(const Duration(days: _trialDays)).toIso8601String());

    state = TrialState(
      isActive: true,
      hasUsedTrial: true,
      startedAt: now,
      daysRemaining: _trialDays,
    );
  }

  Future<void> endTrial() async {
    final box = Hive.box('settings');
    await box.put('isPro', false);
    await box.put('proExpiry', '');
    state = state.copyWith(isActive: false, daysRemaining: 0);
  }

  int get trialDays => _trialDays;
}

final trialProvider = StateNotifierProvider<TrialService, TrialState>(
  (_) => TrialService(),
);
