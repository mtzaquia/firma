//
//  Copyright (c) 2026 @mtzaquia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
@_exported import IdentifiedCollections
import SwiftUI

public struct FormulaireBuilder<F: Formulaire> {
    @Binding var formulaire: F
    let scrollProxy: ScrollViewProxy
    @FocusState.Binding var focus: FormulairePath?
    let renderedFields: Binding<[FormulairePath]>
    let focusCandidates: Binding<[FormulairePath]>
    let validator: Validator
    let path: FormulairePath
    let validateFunction: () -> ValidationResult

    /// Runs validation and returns an immutable snapshot of the relevant scope.
    @discardableResult
    public func validation() -> ValidationResult {
        if path == .root {
            return formulaire.runValidation()
        }
        return validateFunction()
    }

    /// Runs validation and reports whether the relevant scope is valid.
    @discardableResult
    public func validate() -> Bool {
        validation().isValid
    }

    /// Focuses a rendered, focusable field.
    ///
    /// - Returns: `true` when the field is currently registered as focusable.
    @discardableResult
    public func focus<S>(on field: FieldPath<F, S>) -> Bool {
        let fieldPath = path.appending(field: F.__fields[keyPath: field].label)
        guard renderedFields.wrappedValue.contains(fieldPath) else {
            return false
        }

        focusCandidates.wrappedValue = []
        scrollProxy.scrollTo(fieldPath)
        DispatchQueue.main.async {
            focus = fieldPath
        }
        return true
    }

    /// Returns a native binding for a field.
    public func binding<V>(for field: FieldPath<F, V>) -> Binding<V> {
        let concreteField = F.__fields[keyPath: field]
        return Binding(
            get: { concreteField.get(formulaire) },
            set: { concreteField.set(formulaire, $0) }
        )
    }

    /// Returns the current error for a field, if one exists.
    public func error<V>(for field: FieldPath<F, V>) -> (any Error)? {
        let concreteField = F.__fields[keyPath: field]
        return validator.errors[path.appending(field: concreteField.label)]
    }

    /// Scopes to the identified child currently stored in a list.
    ///
    /// Returning `nil` prevents a stale or foreign child from creating a phantom
    /// form row.
    public func scope<S: Formulaire & Identifiable>(
        _ field: FieldPath<F, IdentifiedArrayOf<S>>,
        id: S.ID
    ) -> FormulaireBuilder<S>? {
        let concreteField = F.__fields[keyPath: field]
        guard let initialValue = concreteField.get(formulaire)[id: id] else {
            return nil
        }

        let childPath = path
            .appending(field: concreteField.label)
            .appending(elementID: id)

        return FormulaireBuilder<S>(
            formulaire: Binding(
                get: {
                    concreteField.get(formulaire)[id: id] ?? initialValue
                },
                set: { newValue in
                    var list = concreteField.get(formulaire)
                    guard list[id: id] != nil else { return }
                    list[id: id] = newValue
                    concreteField.set(formulaire, list)
                }
            ),
            scrollProxy: scrollProxy,
            focus: $focus,
            renderedFields: renderedFields,
            focusCandidates: focusCandidates,
            validator: validator,
            path: childPath,
            validateFunction: {
                guard let child = concreteField.get(formulaire)[id: id] else {
                    return ValidationResult()
                }
                return validator.replaceValidation(of: child, at: childPath)
            }
        )
    }

    /// Scopes to a child from an identified list.
    ///
    /// Prefer ``scope(_:id:)`` when the caller can naturally work with an ID.
    public func scope<S: Formulaire & Identifiable>(
        _ field: FieldPath<F, IdentifiedArrayOf<S>>,
        for child: S
    ) -> FormulaireBuilder<S>? {
        scope(field, id: child.id)
    }

    /// Scopes to a nested Formulaire subject.
    public func scope<S: Formulaire>(_ field: FieldPath<F, S>) -> FormulaireBuilder<S> {
        let concreteField = F.__fields[keyPath: field]
        let childPath = path.appending(field: concreteField.label)

        return FormulaireBuilder<S>(
            formulaire: Binding(
                get: { concreteField.get(formulaire) },
                set: { concreteField.set(formulaire, $0) }
            ),
            scrollProxy: scrollProxy,
            focus: $focus,
            renderedFields: renderedFields,
            focusCandidates: focusCandidates,
            validator: validator,
            path: childPath,
            validateFunction: {
                validator.replaceValidation(of: concreteField.get(formulaire), at: childPath)
            }
        )
    }

    /// Scopes to a nested optional Formulaire subject when it exists.
    public func scope<S: Formulaire>(
        _ field: FieldPath<F, Optional<S>>
    ) -> FormulaireBuilder<S>? {
        let concreteField = F.__fields[keyPath: field]
        guard let initialValue = concreteField.get(formulaire) else {
            return nil
        }

        let childPath = path.appending(field: concreteField.label)
        return FormulaireBuilder<S>(
            formulaire: Binding(
                get: {
                    concreteField.get(formulaire) ?? initialValue
                },
                set: { concreteField.set(formulaire, $0) }
            ),
            scrollProxy: scrollProxy,
            focus: $focus,
            renderedFields: renderedFields,
            focusCandidates: focusCandidates,
            validator: validator,
            path: childPath,
            validateFunction: {
                guard let child = concreteField.get(formulaire) else {
                    validator.clearAllErrors(in: childPath)
                    return ValidationResult()
                }
                return validator.replaceValidation(of: child, at: childPath)
            }
        )
    }
}
