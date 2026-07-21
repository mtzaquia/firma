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

import IdentifiedCollections
import SwiftUI

public extension FirmaBuilder {
    /// Scopes to the identified child currently stored in a list.
    ///
    /// Returning `nil` prevents a stale or foreign child from creating a phantom
    /// form row.
    func scope<S: Firma & Identifiable>(
        _ field: FieldPath<F, IdentifiedArrayOf<S>>,
        id: S.ID
    ) -> FirmaBuilder<S>? {
        let resolvedField = resolve(field)
        let concreteField = resolvedField.field
        let values = concreteField.get(firma)
        focusCoordinator.registerElementOrder(
            FirmaElementOrder(
                listPath: resolvedField.path,
                currentIDs: {
                    concreteField.get(firma).map { AnyHashable($0.id) }
                }
            )
        )
        guard let initialValue = values[id: id] else {
            return nil
        }

        let childPath = resolvedField.path
            .appending(elementID: id)

        return makeScopedBuilder(
            binding: FirmaRetainedBinding.make(
                initialValue: initialValue,
                currentValue: { concreteField.get(firma)[id: id] },
                setIfPresent: { newValue in
                    var list = concreteField.get(firma)
                    list[id: id] = newValue
                    concreteField.set(firma, list)
                }
            ),
            path: childPath,
            validation: {
                guard let child = concreteField.get(firma)[id: id] else {
                    return ValidationResult()
                }
                return validator.replaceValidation(of: child, at: childPath)
            }
        )
    }

    /// Scopes to a nested Firma subject.
    func scope<S: Firma>(_ field: FieldPath<F, S>) -> FirmaBuilder<S> {
        let resolvedField = resolve(field)
        let concreteField = resolvedField.field
        let childPath = resolvedField.path

        return makeScopedBuilder(
            binding: Binding(
                get: { concreteField.get(firma) },
                set: { concreteField.set(firma, $0) }
            ),
            path: childPath,
            validation: {
                validator.replaceValidation(of: concreteField.get(firma), at: childPath)
            }
        )
    }

    /// Scopes to a nested optional Firma subject when it exists.
    func scope<S: Firma>(
        _ field: FieldPath<F, Optional<S>>
    ) -> FirmaBuilder<S>? {
        let resolvedField = resolve(field)
        let concreteField = resolvedField.field
        guard let initialValue = concreteField.get(firma) else {
            focusCoordinator.removeElementOrders(in: resolvedField.path)
            return nil
        }

        let childPath = resolvedField.path
        return makeScopedBuilder(
            binding: FirmaRetainedBinding.make(
                initialValue: initialValue,
                currentValue: { concreteField.get(firma) },
                setIfPresent: { concreteField.set(firma, $0) }
            ),
            path: childPath,
            validation: {
                guard let child = concreteField.get(firma) else {
                    validator.removeErrors(in: childPath)
                    return ValidationResult()
                }
                return validator.replaceValidation(of: child, at: childPath)
            }
        )
    }

    private func makeScopedBuilder<S: Firma>(
        binding: Binding<S>,
        path: FirmaPath,
        validation: @escaping () -> ValidationResult
    ) -> FirmaBuilder<S> {
        FirmaBuilder<S>(
            firma: binding,
            focusCoordinator: focusCoordinator,
            validator: validator,
            path: path,
            validateFunction: validation
        )
    }
}
