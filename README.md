# ZUS Application – Assessment

A two-screen Flutter assessment: categorized products, a shared in-memory cart,
and simulated checkout. Built with Material 3, Cubit and `go_router`.

The app display name is **ZUS Application – Assessment**. Open the project in
`zus_application_assessment/`; this filesystem-safe name is also the Dart package
name. Android uses `dev.assessment.zus_application_assessment`; iOS uses
`dev.assessment.zusApplicationAssessment`.

## Scope

This is the menu/cart slice requested in the assessment. Authentication, offline
catalog support, disk persistence, custom animations, a custom design system,
and custom platform channels/native features are outside its required scope.
Generated Android/iOS runner files are the standard Flutter host projects.
Tests are optional supporting evidence, not an assessment requirement. Promo
codes and scaling to 2,000 items are written design discussions, not additional
features. Checkout is simulated; no real order or payment backend is required.

## Run

Use Flutter **3.47.6 stable / Dart 3.13.5**, the installed toolchain used for this
submission. The assessment specifies Flutter 3.38.10 or newer; older toolchains
than the one above have not been validated with this generated platform project
and lockfile. Android minimum API is **26**; iOS minimum version is **16**.

```sh
git clone https://github.com/yong190/zus-application-assessment.git zus_application_assessment
cd zus_application_assessment
flutter pub get
flutter devices
flutter run -d <device-id>
```

Android needs Android Studio, a working emulator or connected device, Android SDK
36, build tools, and the NDK version requested by the generated Gradle project.
Use `flutter doctor -v` to resolve local setup issues. iOS builds require macOS,
Xcode and, for a physical device, an appropriate signing team.

No API key, authentication, backend setup or code generation is needed.

## Data and deliberate assumptions

The normal run requests
[`GET /products?limit=0&select=id,title,description,category,price,stock`](https://dummyjson.com/products?limit=0&select=id,title,description,category,price,stock)
from [DummyJSON](https://dummyjson.com/docs/products). Real names and categories
are retained, including non-food products, as permitted by the assessment.

- Fetch once, retain in memory, group by category, and lazily build product rows.
- A request times out after 15 seconds. Network, server and invalid-data failures
  show an error with Retry; an empty result has its own message. Failed requests
  never silently switch to fixtures or clear the cart.
- The source does not supply currency. Numeric prices are assumed **MYR demo
  prices**, rounded once into integer **sen** at the repository boundary.
  A price of `9.99` means `RM9.99`; no exchange-rate conversion is performed.
- Base prices only: no source discounts, minimum-order rules, taxes or fees.
- Numeric stock is authoritative for this UI: zero prevents adding; positive
  stock caps quantity. Stock is a fetched snapshot, not a reservation. Checkout
  does not update or reserve inventory on DummyJSON.
- The cart stores immutable product snapshots keyed by product ID. Decrementing
  from one removes the line; Remove deletes the entire line. A full process
  restart resets state. Navigation and ordinary configuration changes do not.

## Repeatable review modes

These are launch settings, not customer-facing controls. Stop and relaunch to
change them; hot reload does not change compile-time values.

| Command suffix for `flutter run -d <device-id>` | Behavior |
| --- | --- |
| No suffix | Live API; successful simulated checkout |
| `--dart-define=CATALOG_MODE=fixture` | Four deterministic items in two categories; includes zero stock and stock limits of 1, 3 and 5 |
| `--dart-define=CATALOG_MODE=empty` | Empty catalog after a short loading state |
| `--dart-define=CATALOG_MODE=error` | Reproducible menu load failure; Retry repeats the request and failure |
| `--dart-define=CATALOG_MODE=invalid` | Invalid required item data; explicit error and Retry |
| `--dart-define=CHECKOUT_FAIL=true` | Checkout always fails; may be combined with live or fixture data |

For example:

```sh
flutter run -d <device-id> --dart-define=CATALOG_MODE=fixture --dart-define=CHECKOUT_FAIL=true
```

Checkout waits 1.5 seconds. The Cubit synchronously rejects an empty or duplicate
submission, captures an immutable snapshot, and locks all cart mutations before
awaiting the result. Navigation stays available. Success clears the submitted
cart; failure preserves it and enables another attempt. A persistent notice on
either screen retains the outcome until dismissal or the next attempt. There is
no real order, payment or server-side idempotency guarantee.

## Architecture

```text
lib/app.dart                   # Stable router, repository injection and shared Cubit ownership
lib/features/menu/view/        # Page/view and lazy categorized presentation
lib/features/menu/cubit/       # Menu fetch status and immutable grouped catalog
lib/features/menu/data/        # HTTP/fixture providers; repository validation and mapping
lib/features/menu/models/      # Immutable Product and MenuCategory values
lib/features/cart/view/        # Cart lines, summaries and checkout controls
lib/features/cart/cubit/       # Shared quantities, invariants and checkout lifecycle
lib/features/cart/data/        # Injectable simulated checkout repository
lib/features/cart/models/     # Immutable cart lines containing product snapshots
lib/shared/                   # Money formatting, selective quantity control and result notice
```

Presentation depends on Cubits and immutable values; Cubits depend on
constructor-injected repositories; the catalog repository depends on its data
provider. Cubits have no Flutter imports and do not communicate with each other.
`RepositoryProvider` and `BlocProvider` own dependencies above both routes.
`go_router` centralizes the two routes and all navigation; no nested shells or
routing code generation are needed. Cubit fits these direct UI commands with
less event plumbing; its tradeoff is that the submission guard is explicit.

**Promo-code extension (design only):** add code entry and validation feedback to
the cart view, a promo repository/data provider, and discount/validation fields in
cart state. `CartCubit` would validate against a cart revision and discard stale
responses after quantity changes, then derive the discounted total. Menu loading,
product cards, and routing would remain untouched. No speculative promo code is
implemented here.

## Design answers

### 1. State shape and rebuilds

`MenuCubit` owns the catalog and its loading/error state; one `CartCubit` owns
quantities and checkout status for both screens. Loading a catalog and editing a
cart have different lifecycles, while checkout and cart mutation rules must be
updated together. Each menu quantity control selects only its product's quantity
and the submission lock; cart rows, badge and totals have their own selections.
Tapping `+` updates the relevant controls and summaries without refetching products
or rebuilding the catalog builder; submitting changes controls across all items.
Immutable `Equatable` state prevents equal emissions, but selectors provide the
fine-grained rebuild boundary.

### 2. API contract

I would require an explicit currency code and integer minor-unit prices in the
product contract. DummyJSON's numeric price does not establish currency, so the
current adapter documents an MYR assumption and rounds into sen. With that
contract, mapping would validate the currency and accept the integer amount
directly, removing both assumptions and decimal conversion from Flutter code.

### 3. Async edge cases and duplicate submissions

The cart Cubit lives above the router, so leaving the cart does not dispose the
checkout owner, and outcomes remain in state for the currently visible screen.
Submitting is emitted synchronously before the first `await`; both UI controls
and Cubit commands reject duplicate submissions and cart mutations. Success
clears the frozen cart, while failure retains it; callbacks never hold a route's
`BuildContext`, and late responses after Cubit disposal are ignored. Background
execution is not guaranteed by the OS, but a surviving process can resume and
display the result; process-death recovery is outside this in-memory scope.
A real backend would additionally need idempotency keys and authoritative
price/stock validation, because a client-side guard cannot prevent all duplicates.

### 4. Another two hours

I would extend the existing focused tests into an automated device regression suite
for rapid submission, navigating away during checkout, and background/resume
behavior. The current unit and widget tests cover the logic and simulated
lifecycle changes, but do not prove how an actual OS schedules or suspends the
application. Manual Android emulator checks now cover those flows; automating
them would protect the highest-risk behavior in this slice on future changes.

### 5. Scaling to 2,000 items and 40 categories

The first likely bottleneck is fetching, decoding and retaining the entire
catalog before showing it; this needs measurement on a representative device.
Rows are lazy, and grouping happens once in the repository rather than on each
cart update, so widget construction is limited to the visible area and cache.
Cart mutations currently copy the line map and summaries traverse it, so a very
large cart also has linear update costs. I would profile those paths, then add
server-supported paging/category loading and consider background parsing before
introducing more architectural layers.

## Verification

```sh
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
dart run tool/lint.dart
flutter test
flutter build apk --debug
```

`analysis_options.yaml` includes `package:bloc_lint/recommended.yaml`.
The small lint runner invokes the official linter with a proper file URI because
the current `bloc_tools` CLI misreads Windows paths containing spaces.

See [the verification record](docs/verification.md) for executed checks and
remaining platform limitations, and [the acceptance review](docs/acceptance-review.md)
for the PDF requirements and agreed decisions. [Preview images](docs/preview/) were rendered
from the actual Flutter widgets using fixtures and loaded Roboto/Material fonts;
they are not emulator screenshots. [Android emulator screenshots](docs/emulator/)
record the separate API 37 runtime checks, including live networking and recovery,
checkout success/failure, and retained cart state across configuration changes.
