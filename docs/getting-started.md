# Getting started

Formulaire turns the writable properties of an observable class into type-safe field metadata. The macro supports classes, requires `@Observable`, and ignores static, read-only, and computed getter-only properties.

## Define a model

Use explicit property types for public form models so the macro can expose their generated field metadata to other modules.

```swift
import Formulaire
import Observation

@MainActor @Observable @Formulaire
public final class ProfileForm {
  public var displayName: String = ""
  public var age: Int = 18

  public init() {}

  public func validate() {
    if displayName.isEmpty {
      addError(ProfileError.missingName, for: \.displayName)
    }
  }
}
```

Formulaire's runtime is main-actor isolated. Add `@MainActor` when the consuming target does not use main-actor default isolation.

## Render a form

`FormulaireView` supplies a SwiftUI `Form`, focus management, scrolling, and the keyboard toolbar.

```swift
struct ProfileView: View {
  @State private var profile = ProfileForm()

  var body: some View {
    FormulaireView(editing: $profile) { form in
      form.textField(for: \.displayName, label: "Display name")
      form.stepper(for: \.age, label: "Age", range: 0...120)
      form.submitButton("Save") { save(profile) }
    }
  }
}
```

The field arguments are key paths into generated metadata rather than writable model key paths. That keeps the value type known and lets Formulaire attach a stable path to every control and error.

## Bring your own container

`FormulaireContent` provides the same builder and focus system without adding a `Form`, `List`, or scroll view.

```swift
FormulaireContent(editing: $profile) { form in
  ScrollView {
    LazyVStack {
      form.textField(for: \.displayName, label: "Display name")
    }
    .padding()
  }
}
```

Continue with [Validation](validation.md) and [Rendering and focus](rendering.md).
