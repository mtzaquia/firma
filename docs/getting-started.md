# Getting started

A Firma model is an observable class whose writable properties become type-safe fields. The model holds the current values and the rules; a builder turns those fields into bindings, controls, errors, and focus targets.

## Define a model

Apply both `@Observable` and `@Firma`, then implement `validate()`:

```swift
import Firma
import Observation

enum ProfileError: LocalizedError {
  case missingName

  var errorDescription: String? { "Enter a display name" }
}

@Observable @Firma
final class ProfileForm {
  var displayName: String = ""
  var age: Int = 18

  func validate() {
    if displayName.isEmpty {
      addError(ProfileError.missingName, for: \.displayName)
    }
  }
}
```

`@Firma` supports classes and requires `@Observable`. It generates metadata for writable instance properties. Static properties, constants, and getter-only computed properties do not become fields.

Firma's runtime API is main-actor isolated. Keep the model on `@MainActor` unless the consuming target already uses main-actor default isolation.

### Public models

A model used from another module needs the usual public class, initializer, properties, and validation method. Give every public field an explicit type so the macro can expose matching public metadata:

```swift
@Observable @Firma
public final class SettingsForm {
  public var username: String = ""
  public var notificationsEnabled: Bool = true

  public init() {}

  public func validate() {}
}
```

The macro diagnoses a public writable property whose type exists only in its initializer expression.

## Render the form

Own the reference model with `@State` and pass a binding to `FirmaContent`. It supplies validation state, scrolling, focus coordination, and the iOS keyboard controls; the app supplies the visual container.

```swift
import SwiftUI

struct ProfileView: View {
  @State private var profile = ProfileForm()

  var body: some View {
    FirmaContent(editing: $profile) { form in
      Form {
        form.textField(for: \.displayName, label: "Display name")
        form.stepper(for: \.age, label: "Age", range: 0...120)

        form.submitButton("Save") {
          save(profile)
        }
      }
    }
  }
}
```

Although `\.displayName` looks like a writable model key path, Swift infers a key path into the macro-generated field metadata. That metadata carries the value type and lets Firma derive a stable path for rendering and validation.

## Bring your own layout

Replace the native `Form` with any layout without changing the builder or coordination system:

```swift
FirmaContent(editing: $profile) { form in
  ScrollView {
    LazyVStack(alignment: .leading, spacing: 16) {
      form.textField(for: \.displayName, label: "Display name")
      form.stepper(for: \.age, label: "Age", range: 0...120)
      form.submitButton("Save") { save(profile) }
    }
    .padding()
  }
}
```

The content closure remains responsible for the complete visual hierarchy. Firma still observes rendered focusable controls, scrolls to requested identities, and keeps validation attached to the model.

Next: [Validation](validation.md) · [Rendering and focus](rendering.md)
