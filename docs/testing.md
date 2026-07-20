# Testing

The sample application is both an API catalogue and a deterministic UI-test fixture. Open `SampleApp/Sample.xcodeproj` and run the `Sample` scheme to browse it.

## Scenarios

- `controls` exercises both containers, convenience and custom controls, generic labels, styling, manual validation, exact error lookup, programmatic focus, keyboard navigation, and synchronous and asynchronous submit APIs.
- `nesting` exercises deep scopes, subtree errors, parent errors, and optional insertion and removal.
- `dynamic-list` exercises empty-list errors, stable element identity, insertion, removal, reordering, row controls, and first-invalid focus across a five-row lazy form.

The app accepts `UI_TESTING` plus one scenario argument and disables animations for deterministic launches:

```text
UI_TESTING --scenario=controls
UI_TESTING --scenario=nesting
UI_TESTING --scenario=dynamic-list
```

Accessibility identifiers live in `SampleAppAccessibility`; the UI target mirrors those strings in its private `A11y` namespace so production sample code does not become a test-target dependency.

## Run the suites

Run package tests from the repository root:

```sh
swift test
swift build -c release
```

Run the `SampleUITests` scheme from Xcode or with a simulator destination:

```sh
xcodebuild \
  -project SampleApp/Sample.xcodeproj \
  -scheme SampleUITests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  test
```

Package coverage includes validation lifecycle, deep path identity, colliding list hashes, similarly named path boundaries, reused nested objects, optional lifecycle, field metadata, dynamic focus order, macro diagnostics and expansion, and a separate-module public API fixture.
