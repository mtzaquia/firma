# Rendering and focus

Formulaire provides text-field, toggle, stepper, submit, and custom-control APIs. Convenience controls use `FormulaireStyle` from the SwiftUI environment and expose optional accessibility identifiers for stable UI tests.

## Localizable labels

String conveniences are useful for dynamic or verbatim labels. Trailing label builders accept any SwiftUI view and are the preferred path for localization or richer labels.

```swift
form.textField(
  for: \.name,
  prompt: Text("profile.name.prompt"),
  accessibilityIdentifier: "profile.name"
) {
  Label("profile.name", systemImage: "person")
}
```

The stepper uses SwiftUI's native range-aware initializer, so increment and decrement controls disable at the range boundaries.

## Custom controls

`control(for:focusable:)` supplies a `ControlBuilder` with the field binding, current error, stable `FormulairePath`, and shared focus binding.

```swift
form.control(for: \.birthday, focusable: false) { field in
  DatePicker("Birthday", selection: field.$value, displayedComponents: .date)
}

form.control(for: \.code, focusable: true) { field in
  TextField("Code", text: field.$value)
    .focused(field.$focus, equals: field.id)
}
```

Mark a control focusable only when it registers the supplied focus binding. Focus order comes from the controls actually rendered, not from model declaration order. Dynamic insertion, removal, and reordering update that registry; focus is cleared if its control disappears.

## Programmatic focus

`form.focus(on:)` scrolls to a currently rendered focusable field and returns `true`. It returns `false` for hidden, non-focusable, or removed fields.

On iOS, the keyboard toolbar moves to the previous or next rendered focusable field and can dismiss focus. An invalid submit follows validation order, scrolls lazy containers until the first focusable invalid field mounts, and then assigns focus. This keeps long identified lists aligned with model order even when only a subset of rows is currently rendered.

## Submission

`submitButton` and `asyncSubmitButton` always start a fresh validation pass. Their success actions do not run for invalid state.

```swift
form.asyncSubmitButton(action: {
  await client.save(model)
}) {
  Label("Save", systemImage: "tray.and.arrow.down")
}
```

The async action runs in a task on the main actor. The app remains responsible for progress UI, cancellation policy, and preventing duplicate network submissions when those behaviors are required.

## Styling

Apply `formulaireStyle(_:)` to either container to override error, focused-label, and normal-label colors or disable uppercase text-field labels.
