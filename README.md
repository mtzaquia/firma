# 🖋️ Firma

`Firma` is a type-safe abstraction layer to quickly build focus-aware, validated SwiftUI forms.

Keep editable state and validation rules together in an observable model. Firma turns that model into scoped field metadata, bindings, errors, and focus identities that stay correct across nested objects and dynamic collections.

- Validate root fields, nested models, optionals, and identified collections.
- Render ready-made text fields, toggles, and steppers, or connect any SwiftUI control.
- Move focus in visual order and reveal the first invalid field in lazy content.
- Read an exact field error or collect every error below a form section.
- Use a native SwiftUI `Form` or supply the complete layout yourself.

```swift
FirmaContent(editing: $profile) { form in
  Form {
    form.textField(for: \.name, label: "Name")
    form.textField(for: \.email, label: "Email")

    form.submitButton("Save profile") {
      save(profile)
    }
  }
}
```

## Install

Firma 2.0.0 supports iOS 17+ and macOS 14+ and uses Swift 6.2.

```swift
dependencies: [
  .package(
    url: "https://github.com/mtzaquia/firma.git",
    from: "2.0.0"
  ),
]
```

## Five-minute start

Describe the form as an observable class and add `@FormObject`. Its `validate()` method contains the rules; `addError(_:for:)` attaches an error to generated field metadata with the familiar key-path syntax.

```swift
import Firma
import Observation

enum ProfileError: LocalizedError {
  case missingName
  case invalidEmail

  var errorDescription: String? {
    switch self {
    case .missingName: "Enter your name"
    case .invalidEmail: "Enter a valid email address"
    }
  }
}

@Observable @FormObject
final class ProfileForm {
  var name: String = ""
  var email: String = ""
  var receivesUpdates: Bool = false

  func validate() {
    if name.isEmpty {
      addError(ProfileError.missingName, for: \.name)
    }
    if !email.contains("@") {
      addError(ProfileError.invalidEmail, for: \.email)
    }
  }
}
```

Firma's runtime API is main-actor isolated. Add `@MainActor` when the consuming target does not already use main-actor default isolation.

Own the model with SwiftUI, then pass its binding to `FirmaContent`. The app supplies the visual container:

```swift
import SwiftUI

struct ProfileView: View {
  @State private var profile = ProfileForm()

  var body: some View {
    FirmaContent(editing: $profile) { form in
      Form {
        Section("Profile") {
          form.textField(for: \.name, label: "Name")
          form.textField(for: \.email, label: "Email")
          form.toggle(for: \.receivesUpdates, label: "Product updates")
        }

        form.submitButton("Save profile") {
          save(profile)
        }
      }
    }
  }
}
```

The submit button starts a fresh validation pass. If the model is valid, it runs the action. If not, the built-in controls show their errors and Firma scrolls to and focuses the first rendered, focusable field with an error—even when that field lives in lazy content.

`FirmaContent` never imposes a `Form`, `ScrollView`, grid, or other layout. Use `control(for:focusable:)` to connect a custom control to the same binding, validation, identity, and focus system.

That is the core idea: the model owns the rules, scopes preserve field identity, and the builder coordinates rendering, validation, and focus.

## Documentation

- [Getting started](docs/getting-started.md) — define a model and render the first form.
- [Validation](docs/validation.md) — run validation, compose rules, and query errors.
- [Rendering and focus](docs/rendering.md) — containers, controls, styling, focus, and submission.
- [Scoping](docs/scoping.md) — nested models, optionals, and identified collections.
- [Testing](docs/testing.md) — sample scenarios, package tests, and deterministic UI tests.

## Sample app

Open [`SampleApp/SampleApp.xcodeproj`](SampleApp/SampleApp.xcodeproj) to explore built-in and custom controls, manual and asynchronous submission, deep and optional scopes, dynamic identified lists, styling, error summaries, and keyboard navigation.

The `SampleUITests` scheme launches each scenario directly and verifies those same runtime paths. See [Testing](docs/testing.md) for the fixture contract.

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
