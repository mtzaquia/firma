# Validation

A model's `validate()` method describes rules. A validation pass controls lifecycle: it clears stale errors, runs those rules, and returns an immutable `ValidationResult` snapshot.

## Start a pass

From a view builder, prefer `validation()` when the caller needs errors and `validate()` when it only needs a Boolean.

```swift
let result = form.validation()
if result.isValid {
  save()
}
```

Outside a view, call `model.runValidation()`. Calling the rule-producing `model.validate()` method directly does not start a fresh pass and is not a substitute for `runValidation()`.

`ValidationResult.errors` is keyed by `FormulairePath`. Paths retain every nested field and the actual `Hashable` IDs of list elements, so unequal IDs cannot collide even if their hash values do.

`ValidationResult.errorPaths` preserves the order in which validation produced those errors. Identified collections follow their current model order; dictionary iteration order is never used to choose the first invalid field.

## Add field errors

Errors should conform to `LocalizedError` when their user-facing description matters.

```swift
func validate() {
  if email.isEmpty {
    addError(ProfileError.missingEmail, for: \.email)
  }
}
```

One field has at most one current error. Adding another error for the same path in the same pass replaces the earlier one.

## Compose nested validation

Call `validate(_:)` from the parent rule method for nested models, optional models, and identified collections.

```swift
func validate() {
  validate(\.address)
  validate(\.alternateAddress)
  validate(\.attendees)
}
```

Parent-level errors and descendant errors are distinct. For example, an empty attendees list can have an error at `attendees`, while each existing row can have errors beneath `attendees[row-id]`.

## Query errors

In rendering code, `form.error(for:)` returns the exact field error. `form.content(for:)` supplies either the errors in a nested subtree or the top-level error for an identified list.

Validation snapshots do not update after creation. Run another pass to obtain a new result after editing the model.
