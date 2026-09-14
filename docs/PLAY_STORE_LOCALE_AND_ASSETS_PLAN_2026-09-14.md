# Play Store Locales and Store Assets Plan — 2026-09-14

## Implemented in the app source

The localization catalog now contains Arabic, English, French, Spanish, German, Italian, Portuguese, Russian, Turkish, Chinese, Japanese, Korean, Hindi, Indonesian, Persian, and Urdu. Each locale currently has the app title, Smart Analysis label, and upload prompt. The Settings language picker exposes all sixteen locales and persists the selected language locally.

This establishes the localization foundation requested for the future product rollout. It does not claim that every screen has translated copy yet; hard-coded feature-screen strings still require migration to ARB keys before the app can truthfully claim complete UI localization.

## Generated store assets

| Asset | Final file | Dimensions | Notes |
|---|---|---:|---|
| App icon | `store_assets/app_icon_512_final.png` | 512 × 512 | RGB PNG, opaque, 191,064 bytes |
| Feature graphic | `store_assets/feature_graphic_1024x500_final.jpg` | 1024 × 500 | RGB JPEG, opaque, 79,606 bytes |

The assets are prepared for the store listing. Phone and tablet screenshots were intentionally not generated in this task, as requested.

## Play Console status

The Sign in details declaration is saved as **Yes** because the application contains optional paid access tiers. No account or password is required; the saved reviewer instructions explain that the app opens directly and that a purchase is not required for review. Target audience is saved as 13–15, 16–17, and 18 and over. The app has no child-directed audience and no ads.

The remaining store-preparation work is the category/contact form, Content rating questionnaire, store listing text and translations, uploading the icon/feature graphic, creating or updating Play products, and configuring regional prices. The application was not sent for review.

## Billing target configuration requiring confirmation

The repository catalog defines the following target prices, which must be entered in Play Console only after the owner confirms the billing change:

| Product ID | Product | Target US price | Target Algeria price |
|---|---|---:|---:|
| `pro_monthly` | Pro Monthly subscription | $4.99/month | 1,400 DZD/month |
| `pro_yearly` | Pro Yearly subscription | $29.99/year | 6,800 DZD/year |
| `credits_100` | 100 credits | $4.99 | 1,400 DZD |
| `credits_500` | 500 credits | $19.99 | 5,500 DZD |
| `credits_1200` | 1,200 credits | $39.99 | 11,000 DZD |
| `lifetime` | Lifetime Access non-consumable | $79.99 | 22,000 DZD |

Play may calculate local prices and taxes differently. The final regional price shown by Google Play is authoritative.
