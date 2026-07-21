# Testing

The sample application is both an API catalogue and a deterministic UI-test fixture. Open `SampleApp/SampleApp.xcodeproj` and run the `Sample` scheme to browse it.

## Sample scenarios

The catalogue contains three focused screens:

- **Controls and focus** uses `FirmaContent`, every convenience control, a focusable custom control, manual validation, exact error lookup, programmatic focus, styling, synchronous submission, and asynchronous submission.
- **Nesting** uses deep and optional scopes, parent and descendant errors, subtree summaries, and optional insertion and removal.
- **Dynamic lists** uses an `IdentifiedArrayOf`, collection-level errors, stable row identity, insertion, deletion, reordering, and first-invalid focus through a long lazy form.

The app accepts `UI_TESTING` and a scenario argument so UI tests can bypass the catalogue and launch a known fixture directly:

```text
UI_TESTING --scenario=controls
UI_TESTING --scenario=nesting
UI_TESTING --scenario=dynamic-list
```

UI-testing launches disable animations. Accessibility identifiers are defined by `SampleAppAccessibility`; the test target mirrors those strings in its private `A11y` namespace so production sample code does not depend on a test bundle.

## Run package tests

From the repository root:

```sh
swift test
swift build -c release
```

The package suites cover validation lifecycle, nested path identity, hash-colliding collection IDs, similarly named path boundaries, reused child models, optional lifecycle, generated field metadata, dynamic focus order, macro diagnostics and expansion, and a separate-module public API fixture.

## Run UI tests

Run the `SampleUITests` scheme in Xcode, or select an installed simulator from the command line:

```sh
xcodebuild \
  -project SampleApp/SampleApp.xcodeproj \
  -scheme SampleUITests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  test
```

Replace the simulator name when that runtime is not installed. The tests launch each scenario with the arguments above and exercise the same behavior presented by the catalogue.

When extending the sample, keep scenario data and accessibility identifiers deterministic. A scenario should remain useful to a person browsing the app while exposing one stable launch path for automation.
