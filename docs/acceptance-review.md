# Submission acceptance review

Reviewed against all four pages of the Senior Flutter Developer assessment and
the decisions recorded during the design discussion, on 21 October 2026.
Evidence consists of source inspection, automated checks, and the Android
emulator checks recorded in [verification.md](verification.md).

## Required by the PDF

| Requirement | Result and evidence |
| --- | --- |
| Null-safe Dart; Flutter 3.38.10 or newer | Pass: Dart 3 source; validated using Flutter 3.47.6 / Dart 3.13.5. The README names the tested toolchain. |
| Android minimum API 26; iOS minimum 16 | Configuration passes: Android `minSdk = 26`; all three Xcode project configurations target iOS 16. Android builds and runs; iOS build/runtime remains unverified on this Windows host. |
| Material 3 | Pass: explicitly enabled in light and dark themes in `lib/app.dart`. |
| Public categorized list API and documented setup | Pass: DummyJSON products, selected fields, assumptions, and launch commands documented in the README. |
| Categorized menu with name, description, price and availability | Pass: repository grouping and lazy category/product slivers in `menu_view.dart`; live API seen on Android. |
| Visually distinct out-of-stock items that cannot be added | Pass: distinct card background and availability text; disabled controls plus the Cubit's stock guard. Verified using zero-stock coffee. |
| Add from menu and show current quantity inline | Pass: `QuantityControl` selects shared cart state; menu/cart quantities match. |
| Menu loading, error and Retry | Pass: explicit states; offline error and successful retry verified on Android. |
| Reachable cart with every selected item and increment/decrement/remove | Pass: `go_router` route, keyed cart rows, controls and removal. Multiple-row updates/removal also verified by a focused view test. |
| Running total | Pass: integer sen arithmetic and RM formatting; two RM9.99 items total RM19.98. |
| Checkout loading, success, failure and duplicate guard | Pass: synchronous submission lock, immutable order snapshot, 1.5-second simulated repository, persistent outcome, retry after failure. Unit tests assert one request during repeated submissions. |
| Cart survives menu/cart navigation, rotation, theme changes and resizing | Pass: Cubit ownership above stable router; verified in widget tests and on Android API 37. |
| README setup and architecture note | Pass: toolchain, API, commands, folder responsibilities, dependency injection and dependency direction are documented. |
| Written promo-code extension | Pass: README explains cart view/state and repository changes; menu/routing stay unaffected. No promo feature implemented. |
| Five design answers, 2-5 sentences each | Pass: state/rebuilds, API contract, async/duplicates, another two hours, and scaling are answered within that length. |
| GitHub repository link | Pass: public repository [yong190/zus-application-assessment](https://github.com/yong190/zus-application-assessment), published for submission on 22 October 2026. |

## Agreed decisions beyond the minimum PDF requirements

| Decision | Result |
| --- | --- |
| Flutter Bloc skill architecture; no extra Clean Architecture layers | Pass: feature folders, thin views, constructor-injected repositories/providers, pure Dart Cubits, no Cubit-to-Cubit dependency. |
| Shared state where needed; separate unrelated lifecycles | Pass: one `CartCubit` serves both screens; `MenuCubit` separately owns catalog loading. Both live above the routes to retain state. |
| Immutable state | Pass: final fields, Equatable props, defensive unmodifiable collection copies, const initial states and immutable products/cart lines. |
| Selective rebuilds | Pass: per-product quantity/lock selection, independent badge/summary selection and cart row selection. Review test confirms another item's control and catalog title are not rebuilt on a quantity change. |
| Explicit go_router navigation | Pass: all app navigation uses go_router; no mixed imperative Navigator calls. |
| RM currency and accurate totals | Pass: documented MYR demonstration assumption, rounded once to sen; no invented exchange conversion. |
| Stock cap, decrement-to-remove, empty checkout disabled | Pass: UI and Cubit guards; covered by automated and emulator checks. |
| Safe navigation/background during checkout | Pass: no asynchronous callback retains a route context; shared Cubit owns the result, checks disposal, and blocks edits until completion. Android background/resume was verified with the process alive. |
| Retained success/error feedback and failure retry | Pass: state-driven notice is visible on both screens; success clears cart and failure preserves it. |
| Android emulator for current runtime verification | Pass: API 37 emulator verified. iOS remains a declared platform verification limitation. |

## What is explicitly not required

Page 3 excludes authentication/accounts; offline support or persistence beyond
memory/restoration; unit/widget/integration tests; extra animations; a custom
design system; and platform channels/native code. These are not missing features.
The application uses memory only and standard Material behavior. Generated
Flutter platform runners do not introduce a custom native feature.

The existing tests and two focused review tests are optional verification of the
agreed behavior. They do not expand the product requirements. The PDF also permits
simulated checkout, so a real backend is not a gap. Promo codes and the 2,000-item
scenario require explanation only; implementing them would exceed this slice.

## Review outcome

No missing required app behavior was found. This review added focused evidence
for selective rebuilding and multi-item cart rendering, documented the exclusions
explicitly, and made the acceptance status traceable. No production Dart behavior
or additional feature was introduced. The public GitHub submission link is recorded above; iOS build/runtime
validation remains unavailable on this host. The PDF's
3-4 hour guidance should be respected; optional further enhancements are deferred.

## Final scope and naming check

The renamed project is **ZUS Application – Assessment**, with
`zus_application_assessment` as its folder and Dart package name. The Android and
iOS display names, identifiers, Android activity package, app class and test
imports were updated together. Menu and cart behavior remains unchanged.

All direct runtime dependencies serve the implemented slice: Bloc/Cubit state,
immutable value equality, go_router navigation, and HTTP catalog loading. The
dev dependencies provide the requested Bloc skill's linting/testing workflow.
Fixture modes reproduce required loading/error/stock/checkout states; they are
launch settings and do not add customer-facing functionality. There is no extra
authentication, persistence, payment, promo implementation, custom animation or
custom native feature to remove. The app remains two screens, with standard
Material 3 presentation and no additional architecture layers.
