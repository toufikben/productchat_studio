import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

class ReferralResult {
  final String status; // success, invalid, alreadyUsed, ownCode, limitReached
  final int credits;
  const ReferralResult(this.status, {this.credits = 0});

  static const invalid = ReferralResult('invalid');
  static const alreadyUsed = ReferralResult('alreadyUsed');
  static const ownCode = ReferralResult('ownCode');
  static const limitReached = ReferralResult('limitReached');
  factory ReferralResult.success({required int credits}) => ReferralResult('success', credits: credits);
}

class ReferralService {
  static const _myCodeKey = 'myReferralCode';
  static const _usedKey = 'usedReferrals';
  static const _rewardPerReferral = 20;
  static const _maxReferrals = 50;

  static String getMyCode() {
    final box = Hive.box<dynamic>('settings');
    var code = box.get(_myCodeKey) as String?;
    if (code != null) return code;
    code = _generate();
    box.put(_myCodeKey, code);
    return code;
  }

  static String _generate() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  static Future<ReferralResult> applyCode(String code) async {
    code = code.trim().toUpperCase();
    if (code.length != 8) return ReferralResult.invalid;

    final box = Hive.box<dynamic>('settings');
    final used = List<String>.from(box.get(_usedKey, defaultValue: []) as List);
    if (used.contains(code)) return ReferralResult.alreadyUsed;
    if (code == getMyCode()) return ReferralResult.ownCode;
    if (used.length >= _maxReferrals) return ReferralResult.limitReached;

    used.add(code);
    await box.put(_usedKey, used);

    final credits = Hive.box<dynamic>('credits');
    final current = credits.get('balance', defaultValue: 0) as int;
    await credits.put('balance', current + _rewardPerReferral);

    return ReferralResult.success(credits: _rewardPerReferral);
  }

  static int getReferralCount() =>
      (Hive.box<dynamic>('settings').get(_usedKey, defaultValue: []) as List).length;

  static int getTotalRewards() => getReferralCount() * _rewardPerReferral;

  static String inviteLink() => 'https://productchat.app/invite?code=${getMyCode()}';
}
