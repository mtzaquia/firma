# Scoping

A scope creates a builder for a child model while preserving its complete path from the root. The child receives live bindings, current errors, validation access, and field identities in that path.

## Nested models

Scope one level at a time, then render the child with its own generated field metadata:

```swift
let address = form.scope(\.address)
address.textField(for: \.street, label: "Street")
address.textField(for: \.city, label: "City")

let country = address.scope(\.country)
country.textField(for: \.code, label: "Country code")
```

An error on the last control has a path such as `address.country.code`. This avoids flattening similarly named properties from separate branches into the same validation or focus identity.

Scoping renders a child; it does not implicitly validate it. Compose the same relationship in the parent model's rules:

```swift
func validate() {
  validate(\.address)
}
```

## Optional models

An optional scope returns `nil` while the child is absent:

```swift
if let alternate = form.scope(\.alternateAddress) {
  alternate.textField(for: \.street, label: "Alternate street")

  Button("Remove address", role: .destructive) {
    form.binding(for: \.alternateAddress).wrappedValue = nil
  }
} else {
  Button("Add address") {
    form.binding(for: \.alternateAddress).wrappedValue = AddressForm()
  }
}
```

The parent may attach an error directly to the optional field, validate the child when present, or do both:

```swift
func validate() {
  if alternateAddress == nil {
    addError(AccountError.needsAlternateAddress, for: \.alternateAddress)
  }
  validate(\.alternateAddress)
}
```

SwiftUI can briefly retain an old child view while removing an optional. During that transition, Formulaire keeps the last value readable, ignores stale writes, and removes descendant focus registrations and errors once the child is gone.

## Identified collections

Formulaire uses `IdentifiedArrayOf` from `swift-identified-collections` so row identity follows each element's `ID` rather than an array index.

```swift
ForEach(model.attendees) { attendee in
  if let row = form.scope(\.attendees, id: attendee.id) {
    row.textField(for: \.name, label: "Attendee name")
    row.stepper(for: \.ticketCount, label: "Tickets", range: 1...8)
  }
}
```

The scope returns `nil` if that ID is no longer present. Passing the ID instead of a captured model value prevents a stale or foreign value from creating a phantom row.

Insertion, deletion, and reordering preserve the association between an element and its errors or focus targets. The collection's current order also drives nested validation order and reconciles keyboard navigation through rendered rows.

A collection field and its elements occupy different paths. Query the exact collection error with `form.error(for: \.attendees)`, or include every row error with `form.errors(for: \.attendees)`.

Next: [Validation](validation.md#compose-nested-rules) · [Rendering and focus](rendering.md#focus)
