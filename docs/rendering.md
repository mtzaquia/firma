# Rendering and focus

Firma separates form behavior from layout. Choose the container the screen needs, then mix convenience controls with any custom SwiftUI view.

## Choose a layout

`FirmaContent` installs the builder, validation, scrolling, and focus coordination while the app owns the complete visual hierarchy. For a native SwiftUI form:

```swift
FirmaContent(editing: $model) { form in
  Form {
    Section("Account") {
      form.textField(for: \.email, label: "Email")
    }
  }
}
```

For a custom layout:

```swift
FirmaContent(editing: $model) { form in
  ScrollView {
    LazyVStack(spacing: 16) {
      form.textField(for: \.email, label: "Email")
    }
    .padding()
  }
}
```

Both layouts use the same builder API.

## Convenience controls

| API | Field type | Behavior |
| --- | --- | --- |
| `textField(for:...)` | `String` | Focusable text input with prompt, label styling, and error text. |
| `toggle(for:...)` | `Bool` | Native toggle with label and error text. |
| `stepper(for:...)` | `Int` | Native stepper with optional step and closed range. |
| `control(for:focusable:...)` | Any | Binding, error, identity, and framework-managed optional focus for an app-owned control. |

The stepper uses SwiftUI's range-aware initializer, so increment and decrement disable at the supplied boundaries.

String-label overloads create verbatim labels and are useful for dynamic text. Use the trailing label builders for localized keys, icons, or richer content:

```swift
form.textField(
  for: \.name,
  prompt: Text("profile.name.prompt"),
  accessibilityIdentifier: "profile.name"
) {
  Label("profile.name", systemImage: "person")
}
```

Toggle label builders also accept an explicit `accessibilityLabel`. Every convenience control can receive an accessibility identifier for stable UI tests.

## Bindings and custom controls

Use `form.binding(for:)` when a native control needs only the field binding:

```swift
DatePicker(
  "Birthday",
  selection: form.binding(for: \.birthday),
  displayedComponents: .date
)
```

Use `control(for:focusable:)` when it should also receive the current error and stable path. Passing `focusable: true` binds the returned content to Firma's shared focus state:

```swift
form.control(for: \.referralCode, focusable: true) { field in
  VStack(alignment: .leading) {
    TextField("Referral code", text: field.$value)
    if let error = field.error {
      Text(error.localizedDescription)
        .foregroundStyle(.red)
    }
  }
}
```

Set `focusable: true` when the returned content has one focus destination. Firma applies the focus binding automatically and registers the control in visual focus order. A non-text control such as a `DatePicker` can use `focusable: false` and still receive its binding and error.

## Focus

Focusable controls register in rendered visual order, not model declaration order. Dynamic insertion, deletion, and reordering update that order; removing the focused control clears focus.

Request a field programmatically with `form.focus(on:)`:

```swift
if form.error(for: \.email) != nil {
  _ = form.focus(on: \.email)
}
```

The Boolean reports whether Firma accepted the request. Assignment can happen later, after a lazy destination scrolls into view and mounts, so the field may still disappear before focus is assigned.

On iOS, the keyboard controls move backward and forward through the retained visual order and dismiss the current field. Programmatic focus and invalid submission use the same candidate-based scroll, mount, and focus process. Removed candidates are skipped; newly mounted rows extend the order.

## Submission

Synchronous and asynchronous submit buttons always begin with a fresh validation pass:

```swift
form.submitButton("Save") {
  save(model)
}

form.asyncSubmitButton(action: {
  await client.save(model)
}) {
  Label("Upload", systemImage: "tray.and.arrow.up")
}
```

The success action does not run while the form is invalid. Instead, Firma requests the first focusable error in validation order.

The asynchronous action runs in a main-actor task. Its button disables while that task is active, duplicate taps are ignored, and the task is cancelled if the button disappears. The action should cooperate with cancellation; the app remains responsible for progress, error, and retry presentation.

## Styling

`firmaStyle(_:)` changes the convenience controls in one environment subtree:

```swift
FirmaContent(editing: $model) { form in
  Form {
    // ...
  }
}
.firmaStyle(
  FirmaStyle(
    errorColor: .orange,
    focusedLabelColor: .purple,
    labelColor: .secondary,
    uppercasesTextFieldLabels: false
  )
)
```

Custom controls own their complete appearance. Their `ControlBuilder` supplies enough state to follow the same visual language when desired.

Next: [Scoping](scoping.md) · [Validation](validation.md)
