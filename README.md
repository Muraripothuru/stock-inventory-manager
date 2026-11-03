# Stock Inventory Manager

A Flutter app to add stock items (validated), save them to Firestore, and search, filter, sort and spot low stock.

## Technologies

Flutter, Dart, Firebase Core, Cloud Firestore (FlutterFire).

## Required dependencies

`firebase_core`, `cloud_firestore`, `cupertino_icons`; dev: `flutter_lints`, `flutter_test`.

## Setup instructions

1. Install Flutter 3.x and the Android SDK.
2. `flutter pub get`
3. Firebase is pre-configured: `android/app/google-services.json` and `lib/firebase_options.dart` (from `flutterfire configure`); Google Services Gradle plugin wired in `android/settings.gradle.kts` / `android/app/build.gradle.kts`. Do not edit these.
4. `firestore.rules` deploys open read/write rules (demo use, no auth). Restrict before real-world use.

## Run

```
flutter pub get
flutter run
```

Verified: `flutter build apk --debug`. Release needs signing config.

## Firebase configuration

Initialised in `lib/main.dart` via `DefaultFirebaseOptions.currentPlatform`. Project `stock-inventory-mgr`, package `com.example.stock_inventory`, Firestore database `(default)` in `asia-southeast1`. No keys documented here; they live in the generated config files.

## Firestore schema

Collection `stockItems`, auto-generated IDs. Fields: `sku` (String, e.g. STK-101), `itemName` (String), `category` (Electronics|Stationery|Hardware|Grocery), `quantity` (Integer), `unitPrice` (Number), `reorderLevel` (Integer), `createdAt` (server Timestamp, `FieldValue.serverTimestamp()`).

## Validation

`Form` + `GlobalKey<FormState>`. SKU must match `STK-\d{3}`; name trimmed, min 3 chars; category required; quantity/reorder level whole integers >= 0; price valid number > 0. Firestore is written only when validation passes.

## Search and filtering

Live `StreamBuilder`. Keyword matches itemName OR sku, partial, case-insensitive. Category filter + Low Stock Only combine with AND. Sorting: quantity asc/desc (default newest). Clear Filters resets all. Filtering runs client-side on the latest snapshot.

## Low-stock calculation

`isLowStock => quantity <= reorderLevel`. Low-stock items show a red badge and border.

## Test log

| # | Test | Expected | Result |
|---|------|----------|--------|
| 1 | Submit empty form; SKU `ABC-99` | Field-level errors; no Firestore write | Pass — automated widget tests (`test/widget_test.dart`) |
| 2 | Firestore save & retrieval | Record persists and is re-listed | Write/read/delete verified against `stockItems` via REST (temp doc `STK-999`, then removed; collection left empty). Full UI save/restart check: pending manual demo on device/emulator |
| 3 | Search `mouse` + Electronics + Low Stock Only | Only STK-103 listed | Not yet device-tested; filter logic implemented (AND) and pending manual demo on device/emulator |
