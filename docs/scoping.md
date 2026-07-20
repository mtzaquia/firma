# Scoping

Scopes create a `FormulaireBuilder` for a child while preserving the full path from the root model. Bindings and validation remain live through every level.

## Nested models

```swift
let address = form.scope(\.address)
address.textField(for: \.street, label: "Street")

let country = address.scope(\.country)
country.textField(for: \.code, label: "Country code")
```

Deep errors retain all ancestors, such as `address.country.code`.

## Optional models

Optional scopes return `nil` when no child is present.

```swift
if let alternate = form.scope(\.alternateAddress) {
  alternate.textField(for: \.street, label: "Alternate street")
} else {
  Button("Add alternate address") {
    model.alternateAddress = AddressForm()
  }
}
```

Removing an optional while SwiftUI is retiring its old controls does not trap; stale writes are ignored and stale reads use the last scoped value until that view disappears.

## Identified collections

Lists use `IdentifiedArrayOf` from `swift-identified-collections`. Prefer the ID overload so a stale or foreign model value cannot create a phantom row.

```swift
ForEach(model.attendees) { attendee in
  if let row = form.scope(\.attendees, id: attendee.id) {
    row.textField(for: \.name, label: "Attendee")
  }
}
```

The scope returns `nil` if the ID is not currently present. Reordering keeps each error and focus identity attached to the actual element ID rather than its index or hash value.
