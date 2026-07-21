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

import SwiftUI

public struct FirmaBuilder<F: Firma> {
    @Binding var firma: F
    let focusCoordinator: FirmaFocusCoordinator
    let validator: Validator
    let path: FirmaPath
    let validateFunction: () -> ValidationResult

    /// Runs validation and returns an immutable snapshot of the relevant scope.
    @discardableResult
    public func validation() -> ValidationResult {
        return validateFunction()
    }

    /// Runs validation and reports whether the relevant scope is valid.
    @discardableResult
    public func validate() -> Bool {
        validation().isValid
    }

    /// Requests focus for a field, scrolling lazy containers when necessary.
    ///
    /// - Returns: `true` when the request was accepted. Focus assignment may be
    ///   delayed until the destination mounts.
    @discardableResult
    public func focus<S>(on field: FieldPath<F, S>) -> Bool {
        focusCoordinator.focus(on: resolve(field).path)
    }

    /// Returns a native binding for a field.
    public func binding<V>(for field: FieldPath<F, V>) -> Binding<V> {
        let concreteField = resolve(field).field
        return Binding(
            get: { concreteField.get(firma) },
            set: { concreteField.set(firma, $0) }
        )
    }

    /// Returns the current error for a field, if one exists.
    public func error<V>(for field: FieldPath<F, V>) -> (any Error)? {
        validator.errors[resolve(field).path]
    }

    /// Returns all current errors attached to a field or any of its descendants.
    public func errors<V>(for field: FieldPath<F, V>) -> [FirmaPath: any Error] {
        validator.result.errors(in: resolve(field).path)
    }

    func resolve<V>(
        _ field: FieldPath<F, V>
    ) -> (field: FirmaField<F, V>, path: FirmaPath) {
        let concreteField = F.__fields[keyPath: field]
        return (concreteField, path.appending(field: concreteField.label))
    }
}
