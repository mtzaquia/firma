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
    let focusCoordinator: FormulaireFocusCoordinator
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
        return focusCoordinator.focus(on: fieldPath)
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

}
