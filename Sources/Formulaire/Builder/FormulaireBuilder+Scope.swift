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

public extension FormulaireBuilder {
    /// Scopes to the identified child currently stored in a list.
    ///
    /// Returning `nil` prevents a stale or foreign child from creating a phantom
    /// form row.
    func scope<S: Formulaire & Identifiable>(
        _ field: FieldPath<F, IdentifiedArrayOf<S>>,
        id: S.ID
    ) -> FormulaireBuilder<S>? {
        let resolvedField = resolve(field)
        let concreteField = resolvedField.field
        let values = concreteField.get(formulaire)
        focusCoordinator.registerElementOrder(
            FormulaireElementOrder(
                listPath: resolvedField.path,
                currentIDs: {
                    concreteField.get(formulaire).map { AnyHashable($0.id) }
                }
            )
        )
        guard let initialValue = values[id: id] else {
            return nil
        }

        let childPath = resolvedField.path
            .appending(elementID: id)

        return makeScopedBuilder(
            binding: FormulaireRetainedBinding.make(
                initialValue: initialValue,
                currentValue: { concreteField.get(formulaire)[id: id] },
                setIfPresent: { newValue in
                    var list = concreteField.get(formulaire)
                    list[id: id] = newValue
                    concreteField.set(formulaire, list)
                }
            ),
            path: childPath,
            validation: {
                guard let child = concreteField.get(formulaire)[id: id] else {
                    return ValidationResult()
                }
                return validator.replaceValidation(of: child, at: childPath)
            }
        )
    }

    /// Scopes to a nested Formulaire subject.
    func scope<S: Formulaire>(_ field: FieldPath<F, S>) -> FormulaireBuilder<S> {
        let resolvedField = resolve(field)
        let concreteField = resolvedField.field
        let childPath = resolvedField.path

        return makeScopedBuilder(
            binding: Binding(
                get: { concreteField.get(formulaire) },
                set: { concreteField.set(formulaire, $0) }
            ),
            path: childPath,
            validation: {
                validator.replaceValidation(of: concreteField.get(formulaire), at: childPath)
            }
        )
    }

    /// Scopes to a nested optional Formulaire subject when it exists.
    func scope<S: Formulaire>(
        _ field: FieldPath<F, Optional<S>>
    ) -> FormulaireBuilder<S>? {
        let resolvedField = resolve(field)
        let concreteField = resolvedField.field
        guard let initialValue = concreteField.get(formulaire) else {
            focusCoordinator.removeElementOrders(in: resolvedField.path)
            return nil
        }

        let childPath = resolvedField.path
        return makeScopedBuilder(
            binding: FormulaireRetainedBinding.make(
                initialValue: initialValue,
                currentValue: { concreteField.get(formulaire) },
                setIfPresent: { concreteField.set(formulaire, $0) }
            ),
            path: childPath,
            validation: {
                guard let child = concreteField.get(formulaire) else {
                    validator.removeErrors(in: childPath)
                    return ValidationResult()
                }
                return validator.replaceValidation(of: child, at: childPath)
            }
        )
    }

    private func makeScopedBuilder<S: Formulaire>(
        binding: Binding<S>,
        path: FormulairePath,
        validation: @escaping () -> ValidationResult
    ) -> FormulaireBuilder<S> {
        FormulaireBuilder<S>(
            formulaire: binding,
            focusCoordinator: focusCoordinator,
            validator: validator,
            path: path,
            validateFunction: validation
        )
    }
}
