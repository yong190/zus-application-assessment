# Verification record

Recorded on 21 October 2026. Flutter 3.47.6 stable, Dart 3.13.5, Windows host.

## Renamed project verification

- Display name: **ZUS Application – Assessment** in Flutter, Android and iOS.
  Folder/package: `zus_application_assessment`. The ASCII folder name avoids an
  observed Flutter analyzer protocol crash with an en dash in the directory path.
- Updated Android namespace/application ID and activity package to
  `dev.assessment.zus_application_assessment`; iOS bundle IDs use
  `dev.assessment.zusApplicationAssessment` (including the test target suffix).
  All Dart test imports and the app root class were updated consistently.
- Regenerated local build configuration after moving the project. Static
  analysis, Bloc lint (19 application files), and all 27 tests passed. The renamed
  Android debug APK built successfully; manifest inspection confirmed the exact
  display name, new launch activity and minimum API 26.
- Installed the renamed app on `emulator-5554`. Live catalog loading, two-item
  RM19.98 total, navigation, repeated checkout taps and background/resume passed.
  Checkout cleared the cart and retained its success notice. No Flutter exception
  or AndroidRuntime fatal error appeared in the app-process log. The old test
  application was removed; the renamed app was left running.
- Screenshots: [renamed cart](emulator/zus-renamed-cart.png) and
  [renamed checkout](emulator/zus-renamed-checkout.png). Earlier screenshots below
  record the unchanged behavior before renaming.
- iOS configuration was updated and inspected, but its build/runtime remains
  unverified on Windows. The public submission repository is [yong190/zus-application-assessment](https://github.com/yong190/zus-application-assessment) (22 October 2026).

## Completed

- Static analysis: no issues.
- Official Bloc linter: zero issues across 19 application Dart files.
- 27 unit/widget tests passed: stock caps, unavailable items, integer totals,
  decrement/removal, immutable snapshots, empty/duplicate submission guards,
  mutation locks, successful and failed checkout, retry, late completion after
  disposal, menu retry/cache behavior, malformed/duplicate product data, and
  explicit empty/error UI, HTTP response shape/status failures, connection errors
  and timeout error mapping.
- Final review added two view checks using injected mock Cubits: unrelated menu
  controls/catalog widgets retain their identity on an item quantity update,
  and multiple cart rows keep correct quantities and totals after removal.
- Formatting, static analysis, official Bloc lint and the full 27-test suite
  passed again after the review. Tests are optional under the assessment.
- Fetched the current live endpoint response with the system HTTP client and
  passed that payload through the app's HTTP adapter and repository using a mock
  transport: 194 valid products, 24 categories and 4 zero-stock products. This
  validates the current data contract; on-device connectivity was also checked below.
- Widget tests exercised shared state through navigation, a light/dark change,
  portrait/landscape resizing, 200% text scaling, and a simulated background/resume
  transition during checkout. These are simulated lifecycle checks, not OS tests.
- Rendered and visually inspected fixture menu, cart, checkout error, dark theme,
  and landscape with 200% text. No layout overflow was reported.

## Platform checks

- Android debug APK: built successfully with Android SDK 36 and minimum API 26.
- Source archive portability: extracted into a fresh directory with no local
  SDK paths or build outputs; `flutter pub get --offline` using the installed
  dependency cache and `flutter build apk --debug --no-pub` both succeeded.
  This validates source packaging and Android build reproducibility with the
  documented toolchain; a completely uncached network setup was not tested.
- Android emulator runtime: passed on the host-launched `emulator-5554`,
  `sdk_gphone16k_x86_64`, API 37. The live APK fetched DummyJSON successfully.
- Live cart: adding two RM9.99 items produced RM19.98 in the cart and matching
  menu quantities. Cart contents survived landscape rotation, dark mode, 200%
  system text size, and a display-size change from 1080x2424 to 900x1600.
- Successful checkout: rapid repeated taps followed by back navigation and
  background/resume produced an empty cart and a retained success notice on
  the menu and cart. Empty checkout was disabled. The automated repository-call
  assertion verifies exactly one submission; the device check verifies the
  observable result, not request count.
- Fixture failure build: apples capped at three (RM29.97); coffee at zero stock
  could not be added. An attempted decrement during checkout was rejected.
  Back navigation and background/resume retained all three items and the error
  notice; retry was enabled and worked. Decrementing to zero and removing a line
  both produced the empty-cart state.
- Live network recovery: disabling Wi-Fi and mobile data produced the connection
  error with Retry. Restoring both and tapping Retry loaded the live catalog.
- App-process Flutter/AndroidRuntime logs showed no Flutter exceptions, layout
  overflows or fatal errors during these checks. Display and connectivity
  settings were restored, and the normal live build was left running.
- [Emulator screenshots](emulator/) capture the live menu/cart, configuration
  change, successful checkout, stock cap, failed checkout, and network failure
  and recovery. Empty/invalid catalog variants were covered by automated widget
  tests; they were not separately installed on the emulator.
- iOS build and runtime: unverified; this host is Windows. Deployment target is
  set to iOS 16 in all app build configurations.

## Repeatable manual acceptance sequence

1. Run live mode: confirm categories, required fields and RM prices.
2. Run fixture mode: add apples up to three; confirm the fourth add and the
   zero-stock coffee controls are disabled. Confirm the cart rejects excess stock.
3. Open the cart, change quantities, remove a line and return to the menu. Confirm
   matching inline quantities and exact totals (two apples = RM19.98).
4. Rotate, resize and change system theme/text size. Confirm state survives and
   all content is reachable by scrolling.
5. Tap Place Order repeatedly, navigate back while pending, and attempt cart
   edits. Confirm one submission and locked controls, followed by a retained
   success notice and empty cart.
6. Repeat with `CHECKOUT_FAIL=true`: confirm retained contents, error notice and
   enabled retry. Background and resume during the delay.
7. Run empty, error and invalid modes. Confirm distinct states and a working
   retry/loading cycle. In live mode, disable connectivity and retry to exercise
   the real network failure path.
8. Empty the cart. Confirm the empty message, Browse menu action and disabled
   Place Order button.
