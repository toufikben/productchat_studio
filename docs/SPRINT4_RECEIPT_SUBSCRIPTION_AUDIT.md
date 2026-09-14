# Sprint 4 — Receipt Verification and Subscription Audit

**Audit date:** 2026-09-14

**Audited commit:** `70f6a13`, including Billing fix `1c21e3d`, documentation commit `4fd32cf`, and restored-consumable hardening.

**Scope:** Flutter `in_app_purchase` integration, purchase stream handling, consumable Credits ledger, subscription products, restore behavior, and receipt/entitlement verification.

## Executive conclusion

The project has a **local purchase-event handler**, not production Receipt Verification. Google Play product IDs and purchase APIs are wired, and the client prevents duplicate grants for transaction IDs retained in local storage. However, the client does not send purchase data to a trusted backend, validate a Google Play purchase token with the Google Play Developer API, maintain a server-side ledger, or derive a durable Pro entitlement from verified subscription state.

**Sprint 4 status:** code-level separation is complete; production billing verification is not complete.

## Findings

| ID | Severity | Finding | Evidence | Impact |
|---|---|---|---|---|
| RV-01 | Critical before production | No receipt/token verification implementation exists. | No receipt verifier, backend endpoint, Google Play Developer API client, service-account integration, or purchase-token validation was found under `lib`, `android`, `test`, or `.github`. `docs/P7_BILLING_VALIDATION.md` correctly marks this pending. | A client-side purchase event alone is not a trusted server record for granting value across devices or defending against replay/tampering. |
| RV-02 | High | Consumable Credits are granted by the client before trusted verification. | `BillingService._handlePurchases()` calls `ledger.addOnce()` for a recognized consumable `purchaseID` on `purchased` or `restored`. | A local ledger protects only the current installation/storage state; it is not a cross-device or server-authoritative ledger. |
| RV-03 | Closed in Sprint 4 hardening | `restored` consumable events could previously reach the local grant path. | Commit under review now rejects restored consumable events and adds a regression test; subscription restored events remain diagnostics only. | Server-led restore is still required for production reconciliation and cross-device accounting. |
| RV-04 | High | Local ledger update is not transactional. | `CreditsLedger.addOnce()` writes the new balance and then writes processed purchase IDs in separate storage operations. | A crash between writes could grant the same purchase again after restart. A backend transaction/unique constraint is required for production. |
| SUB-01 | High | No Pro entitlement state exists. | No `proEntitled`, expiry timestamp, renewal state, acknowledgement state, or subscription-status model exists. | The UI can sell a subscription, but the app cannot reliably unlock or revoke Pro features. |
| SUB-02 | Medium | Subscription events are acknowledged/closed but not verified. | Subscription products use `buyNonConsumable`; purchased/restored subscription events set `error = null` and then may call `completePurchase`. | Completion is not entitlement verification. Expired, cancelled, refunded, or replaced subscriptions are not modeled. |
| SUB-03 | Medium | No account/device binding is configured. | No `obfuscatedAccountId` or backend user identity is passed to the purchase flow. | Cross-device ownership and server-side reconciliation are not available. This may be acceptable for an internal test, not for production Credits/Pro accounting. |
| TEST-01 | High | No integration tests exercise real PurchaseDetails stream outcomes. | `test/billing_service_test.dart` currently covers the pure catalog and ledger only; it does not use a store fake to test pending/error/purchased/restored/completePurchase flows. | Regressions in callbacks, completion, subscription separation, and unknown products can pass CI unnoticed. |

## What is correct in the current code

- Product IDs are centralized and separated into `consumableIds` and `subscriptionIds`.
- `creditsFor()` returns amounts only for consumable packs.
- Subscription products do not grant local Credits after the Sprint 4 fix.
- Pending and error events do not grant Credits.
- A non-null purchase ID and recognized product are required for local consumable granting.
- The local ledger is idempotent for purchase IDs that remain in local storage.
- `completePurchase` is called when `pendingCompletePurchase` is true and the event is no longer pending.
- `restorePurchases()` is not described as restoring consumed Credits, and restored consumable events are rejected by the local grant path; this matches the platform boundary documented in P7.

## Required production design

1. The client sends a purchase token, product ID, package name, platform, app version, and authenticated user ID to a backend over TLS.
2. The backend validates the token with the Google Play Developer API using a server-held service account; no service-account key belongs in the app or Git repository.
3. The backend stores a unique purchase/transaction record and grants Credits in one database transaction. Duplicate tokens must be harmless.
4. Subscription validation stores purchase state, acknowledgement, expiry time, cancellation/refund/revocation state, and linked user ID.
5. The client receives a server-authoritative entitlement response and uses it to enable or disable Pro features.
6. Play Real-time Developer Notifications should reconcile renewals, cancellations, refunds, and expirations.
7. The client should not treat `restorePurchases()` as consumable-credit restoration; it should trigger server reconciliation for the authenticated user.

## Recommended implementation order

| Order | Work item | Exit evidence |
|---:|---|---|
| 1 | Add a backend receipt-validation contract and authenticated user identity. | API/schema document and integration test fixtures with fake responses. |
| 2 | Implement Google Play token validation server-side. | Valid, invalid, expired, refunded, and duplicate token tests. |
| 3 | Add transactional server ledger. | Unique token constraint and exactly-once credit-grant tests. |
| 4 | Add subscription entitlement model and client sync. | Pro enabled/disabled tests for active, expired, cancelled, and refunded states. |
| 5 | Add Flutter store fake tests. | Pending/error/purchased/restored/unknown/completePurchase coverage. |
| 6 | Verify on Internal Testing. | Device logs, Play test-account results, and documented callback behavior. |

## Audit decision

Do **not** mark Receipt Verification, cross-device consumable restore, or Pro subscription access as implemented. The appropriate current state is:

- **Source:** yes for local purchase handling.
- **Wired:** partial for Play purchase flow.
- **Executable:** partial for local Credits only.
- **Automated:** partial; catalog/ledger tests exist, stream integration tests do not.
- **Android verified:** no.
- **Release ready:** no.
