# 🧾 Formulaire

`Formulaire` is a small, type-safe foundation for validated SwiftUI forms.

Describe editable state with an observable class, write validation beside that state, and render controls through a scoped builder. Formulaire keeps bindings, structured error paths, dynamic focus order, and nested models in sync.

- Validate root models, nested models, optionals, and identified collections.
- Build native controls or integrate any custom SwiftUI control.
- Move keyboard focus in rendered order and reach the first invalid row in lazy, dynamic lists.
- Query immutable validation results or errors for one field or subtree.
- Use the built-in `Form` container or bring your own layout and styling.
- Exercise the runtime API through a deterministic sample app and UI-test suite.

```swift
FormulaireView(editing: $account) { form in
  form.textField(for: \.email, label: "Email")
  form.submitButton("Create account") {
    createAccount()
  }
}
```

## Install

Formulaire supports iOS 17+ and macOS 14+ and uses the Swift 6.2 package format.

```swift
dependencies: [
  .package(url: "https://github.com/mtzaquia/formulaire.git", from: "1.3.0"),
]
```

## Five-minute start

Annotate an observable class with `@Formulaire`, then add errors from its `validate()` method. Form models should be main-actor isolated when the consuming target does not already use main-actor default isolation.

```swift
import Formulaire
import Observation

enum SignUpError: LocalizedError {
  case missingName
  case invalidEmail

  var errorDescription: String? {
    switch self {
    case .missingName: "Enter your name"
    case .invalidEmail: "Enter a valid email address"
    }
  }
}

@MainActor @Observable @Formulaire
final class SignUpForm {
  var name: String = ""
  var email: String = ""
  var receivesUpdates: Bool = false

  func validate() {
    if name.isEmpty {
      addError(SignUpError.missingName, for: \.name)
    }
    if !email.contains("@") {
      addError(SignUpError.invalidEmail, for: \.email)
    }
  }
}
```

Render it with the convenience container. A submit action runs only after a fresh, successful validation pass; an invalid submit scrolls to and focuses the first focusable field with an error, including fields in lazy content.

```swift
import SwiftUI

struct SignUpView: View {
  @State private var model = SignUpForm()

  var body: some View {
    FormulaireView(editing: $model) { form in
      Section("Profile") {
        form.textField(for: \.name, label: "Name")
        form.textField(for: \.email, label: "Email")
        form.toggle(for: \.receivesUpdates, label: "Product updates")
      }

      form.submitButton("Create account") {
        // Persist the already-validated model.
      }
    }
  }
}
```

Use `FormulaireContent` for a `ScrollView`, grid, or any other app-owned container. Use `control(for:focusable:)` to connect custom controls to the same binding, focus, identity, and error system.

That is the core idea: the model owns validation rules, structured scopes preserve identity, and the view builder keeps runtime behavior consistent across native and custom controls.

## Documentation

- [Getting started](docs/getting-started.md) — model requirements and the first form.
- [Validation](docs/validation.md) — validation passes, results, errors, and nested rules.
- [Rendering and focus](docs/rendering.md) — containers, controls, styling, focus, and submission.
- [Scoping](docs/scoping.md) — nested models, optionals, and identified collections.
- [Testing](docs/testing.md) — deterministic sample scenarios and UI-test launch arguments.

## Sample app

Open [`SampleApp/Sample.xcodeproj`](SampleApp/Sample.xcodeproj) to exercise convenience and custom controls, manual and asynchronous submission, deep and optional scopes, dynamic identified lists, validation summaries, styling, and keyboard navigation.

The `SampleUITests` scheme launches each scenario directly and verifies the same runtime paths. See [Testing](docs/testing.md) for the fixture contract.

## License

Copyright (c) 2026 @mtzaquia

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
