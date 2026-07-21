# Validation

Validation rules live beside the state they inspect. A validation pass clears stale errors, supplies the model with a `ValidationContext`, and returns an immutable `ValidationResult`.

## Add field errors

Implement `validate(_:)` on the model and attach errors through its context:

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

func validate(_ validation: ValidationContext<AccountForm>) {
  if email.isEmpty {
    validation.addError(AccountError.missingEmail, for: \.email)
  }
  if password.count < 8 {
    validation.addError(AccountError.weakPassword, for: \.password)
  }
}
```

Convenience controls render `error.localizedDescription`, so use `LocalizedError` when the message is user-facing. A field holds at most one error in the current pass; adding a second error at the same path replaces the first.

Editing a value does not run validation automatically. The existing error remains visible until the next pass decides whether it still applies.

## Start a pass

Call `validate()` on either a view builder or a model. Both forms start a pass and return a `ValidationResult`:

```swift
let result = form.validate()

if result.isValid {
  save(model)
} else {
  showErrorCount(result.errors.count)
}
```

Outside a rendered form, use the same operation on the model:

```swift
let result = model.validate()
```

The overloads have distinct roles: callers invoke zero-argument `validate()` to run a pass, while Firma invokes `validate(_:)` with a `ValidationContext` to collect the model's rules. App code should not call the context-taking overload directly.

`submitButton` and `asyncSubmitButton` also start a fresh pass. Their actions run only for a valid result. An invalid submit asks the focus system to reveal the first rendered, focusable field in validation order.

## Compose nested rules

A parent decides which children participate through its `ValidationContext`. The same `validate(_:)` context method supports a nested model, an optional nested model, and an `IdentifiedArrayOf` of models:

```swift
func validate(_ validation: ValidationContext<EventForm>) {
  if attendees.isEmpty {
    validation.addError(EventError.needsAttendee, for: \.attendees)
  }

  validation.validate(\.venue)
  validation.validate(\.alternateVenue)
  validation.validate(\.attendees)
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

A `ValidationResult` is a snapshot and does not change as the model or validator changes. Its `errors` dictionary is keyed by `FirmaPath`; its `errorPaths` array preserves production order for consumers that need a deterministic first error.

Paths retain every field component and each list element's actual `Hashable` ID. Unequal IDs therefore stay distinct even if their hash values collide. `FirmaPath.description` is suitable for diagnostics, but identity never depends on that string.

When constructing a `ValidationResult` directly, supply `errorPaths` if ordering matters. Dictionary iteration order is not a first-error policy.

Next: [Scoping](scoping.md) · [Rendering and focus](rendering.md#submission)
