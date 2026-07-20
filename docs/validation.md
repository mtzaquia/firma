# Validation

Validation rules live beside the state they inspect. A validation pass clears stale errors, runs those rules, and returns an immutable `ValidationResult`.

## Add field errors

Implement `validate()` on the model and attach errors with `addError(_:for:)`:

```swift
enum AccountError: LocalizedError {
  case missingEmail
  case weakPassword

  var errorDescription: String? {
    switch self {
    case .missingEmail: "Enter an email address"
    case .weakPassword: "Use at least eight characters"
    }
  }
}

func validate() {
  if email.isEmpty {
    addError(AccountError.missingEmail, for: \.email)
  }
  if password.count < 8 {
    addError(AccountError.weakPassword, for: \.password)
  }
}
```

Convenience controls render `error.localizedDescription`, so use `LocalizedError` when the message is user-facing. A field holds at most one error in the current pass; adding a second error at the same path replaces the first.

Editing a value does not run validation automatically. The existing error remains visible until the next pass decides whether it still applies.

## Start a pass

From a view builder, call `validation()` when the caller needs the snapshot or `validate()` when it only needs a Boolean:

```swift
let result = form.validation()

if result.isValid {
  save(model)
} else {
  showErrorCount(result.errors.count)
}
```

Outside a rendered form, call the model's `runValidation()`:

```swift
let result = model.runValidation()
```

> [!IMPORTANT]
> Do not call `model.validate()` to start validation. That method only produces rules inside an active pass; `runValidation()` and the builder APIs own clearing, evaluation, and the returned snapshot.

`submitButton` and `asyncSubmitButton` also start a fresh pass. Their actions run only for a valid result. An invalid submit asks the focus system to reveal the first rendered, focusable field in validation order.

## Compose nested rules

A parent decides which children participate by calling `validate(_:)`. The same API supports a nested model, an optional nested model, and an `IdentifiedArrayOf` of models:

```swift
func validate() {
  if attendees.isEmpty {
    addError(EventError.needsAttendee, for: \.attendees)
  }

  validate(\.venue)
  validate(\.alternateVenue)
  validate(\.attendees)
}
```

An absent optional contributes no child errors. Identified collections validate in their current model order. Rendering a scope and validating a child are separate decisions: `form.scope(...)` creates bindings and identities for views, while `validate(...)` composes that child's rules into the parent pass.

Parent and descendant errors remain distinct. The `attendees` field can carry an empty-list error while existing rows carry errors at paths such as `attendees[guest-42].name`.

## Query current errors

The builder exposes the current observable validation state:

```swift
let emailError = form.error(for: \.email)
let addressErrors = form.errors(for: \.address)
```

`error(for:)` performs an exact lookup. `errors(for:)` includes an error on that field and every error below it, which is useful for section summaries.

A `ValidationResult` is a snapshot and does not change as the model or validator changes. Its `errors` dictionary is keyed by `FormulairePath`; its `errorPaths` array preserves production order for consumers that need a deterministic first error.

Paths retain every field component and each list element's actual `Hashable` ID. Unequal IDs therefore stay distinct even if their hash values collide. `FormulairePath.description` is suitable for diagnostics, but identity never depends on that string.

When constructing a `ValidationResult` directly, supply `errorPaths` if ordering matters. Dictionary iteration order is not a first-error policy.

Next: [Scoping](scoping.md) · [Rendering and focus](rendering.md#submission)
