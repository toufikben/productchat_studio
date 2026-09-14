import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Derives a non-reversible local fingerprint from a Play purchase reference.
/// The raw token must never be persisted or written to logs.
class PurchaseSecurity {
  const PurchaseSecurity._();

  static String? fingerprint({
    required String productId,
    required String? verificationData,
  }) {
    final reference = verificationData?.trim();
    if (reference == null || reference.isEmpty || productId.trim().isEmpty) {
      return null;
    }
    final payload = '$productId\u0000$reference';
    return sha256.convert(utf8.encode(payload)).toString();
  }
}
