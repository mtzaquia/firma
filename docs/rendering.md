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

`form.focus(on:)` accepts a focus request immediately, scrolls lazy containers when necessary, and assigns focus after the destination mounts. Its Boolean result reports that the request was accepted; the field may still disappear before assignment.

On iOS, the keyboard toolbar moves through the retained visual order and can dismiss focus. Navigation and invalid submission use the same candidate-based scroll, mount, and focus state machine. Deleted candidates are pruned and skipped, while newly mounted rows extend the order. This keeps long identified lists aligned with their visual order even when only a subset of rows is currently mounted.

## Submission

`submitButton` and `asyncSubmitButton` always start a fresh validation pass. Their success actions do not run for invalid state.

```swift
form.asyncSubmitButton(action: {
  await client.save(model)
}) {
  Label("Save", systemImage: "tray.and.arrow.down")
}
```

The async action runs in a task on the main actor. Its button is disabled while that task is active, duplicate taps are ignored, and the task is cancelled when the button disappears. The action should still cooperate with task cancellation, and apps remain responsible for any richer progress or retry UI.

## Styling

Apply `formulaireStyle(_:)` to either container to override error, focused-label, and normal-label colors or disable uppercase text-field labels.
