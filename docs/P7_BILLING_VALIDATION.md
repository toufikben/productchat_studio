# P7 Credits and Google Play Billing

**Date:** 2026-09-14

**Code release:** `1.0.2+3` is prepared after configuring the subscription products.

**Play Console status (2026-09-14):** The one-time products `credits_100`, `credits_500`, and `credits_1200` were created and activated successfully. Each product is Active and available in 173 countries/regions. Google Play applied regional pricing; the visible Algeria prices were approximately 100 DZD, 550 DZD, and 1,100 DZD respectively after price rounding.

The subscriptions `pro_monthly` and `pro_yearly` were also created. Their auto-renewing base plans `monthly` and `yearly` are Active, with regional pricing applied from approximately 675 DZD/month and 6,800 DZD/year in Algeria. The product IDs match the Flutter code contracts.

## Implemented

- `BillingService` uses the Flutter `in_app_purchase` plugin.
- Product IDs are centralized in `CreditProducts`:
  - `credits_100` → 100 credits
  - `credits_500` → 500 credits
- `credits_1200` → 1200 credits
- `pro_monthly` → 600 credits per month plus Pro features
- `pro_yearly` → 9000 credits per year plus Pro features
- Product details are queried from the store.
- The purchase stream is subscribed to once during service initialization.
- `pending` purchases do not grant credits.
- `error` purchases do not grant credits.
- Credits are granted only for `purchased` transactions with a recognized product ID and non-null stable purchase ID.
- Subscription product IDs use the non-consumable purchase API while credit packs use the consumable purchase API.
- The ledger is idempotent: the same purchase ID cannot grant credits twice.
- Completed purchases are passed to `completePurchase` when required.
- The ledger is persisted through `StorageService`/SharedPreferences.
- Editor operations check the balance before starting and deduct only after a successful native edit result.
- Failed native operations do not deduct credits.
- `/credits` opens the Paywall screen.
- Paywall displays available balance, configured products, purchase errors, pending state, and restore action.
- Purchase handling accepts both `purchased` and `restored` events, rejects blank transaction IDs, exposes the last purchase state/product for UI diagnostics, and keeps loading/error state consistent across stream errors.

## Important platform boundary

Google Play does not restore consumed consumables through `restorePurchases`. The current restore method is kept for platform consistency and future non-consumable products. A production cross-device consumable-credit restore requires a trusted backend receipt ledger, which is not implemented yet.

The product IDs are code-level contracts only. They must also be created and activated in Google Play Console with matching one-time products and subscriptions before real purchases can succeed.

The approved commercial proposal is 0.99 USD for 100 credits, 3.99 USD for 500 credits, 7.99 USD for 1200 credits, 4.99 USD/month for Pro Monthly with 600 credits per period, and 39.99 USD/year for Pro Yearly with 9000 credits per period. Prices are subject to Google Play regional pricing and tax configuration.

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | Passed — no issues |
| `flutter test` | Passed — 10 tests |
| Credits duplicate-grant tests | Passed |
| Negative-balance protection test | Passed |
| Google Play product configuration | Passed for three Active Credits products plus Active `pro_monthly` and `pro_yearly` base plans |
| Google Play Sandbox purchase | Pending test device/test account |
| Receipt/server verification | Pending; not claimed as implemented |
| Production product configuration | Products and subscription base plans created/activated; purchase execution remains pending on a licensed test device |
