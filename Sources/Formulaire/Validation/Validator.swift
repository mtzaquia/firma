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

/// Observable validation state owned by a ``Formulaire`` subject.
///
/// Validation passes are started by ``Formulaire/runValidation()`` or a
/// ``FormulaireBuilder``. Calling a model's rule-producing `validate()` method
/// directly intentionally does not start a new pass.
@Observable
public final class Validator {
    @ObservationIgnored
    private var context: FormulairePath = .root

    @ObservationIgnored
    private var errorPaths: [FormulairePath] = []

    public private(set) var errors: [FormulairePath: any Error] = [:]

    /// The current validation snapshot.
    public var result: ValidationResult {
        ValidationResult(errors: errors, errorPaths: errorPaths)
    }

    /// **[Internal use]** Formulaire models receive an instance from the macro.
    public init() {}

    func addError(_ error: any Error, for field: String) {
        let path = context.appending(field: field)
        if errors[path] == nil {
            errorPaths.append(path)
        }
        errors[path] = error
    }

    func clearAllErrors(in path: FormulairePath? = nil, includingPath: Bool = true) {
        guard let path, path != .root else {
            errors.removeAll()
            errorPaths.removeAll()
            return
        }

        errors = errors.filter { key, _ in
            if key == path {
                return !includingPath
            }
            return !path.contains(key)
        }
        errorPaths.removeAll { errors[$0] == nil }
    }

    func evaluate<F: Formulaire>(_ subject: F, at path: FormulairePath) -> ValidationResult {
        context = path
        errors.removeAll()
        errorPaths.removeAll()
        subject.validate()
        return result
    }

    func replaceValidation<F: Formulaire>(of subject: F, at path: FormulairePath) -> ValidationResult {
        clearAllErrors(in: path, includingPath: false)

        let childResult: ValidationResult
        if subject.__validator === self {
            let preserved = result
            childResult = evaluate(subject, at: path)
            errors = preserved.errors
            errorPaths = preserved.errorPaths
            merge(childResult)
        } else {
            childResult = subject.__validator.evaluate(subject, at: path)
            merge(childResult)
        }

        let scopedErrors = errors.filter { path.contains($0.key) }
        return ValidationResult(
            errors: scopedErrors,
            errorPaths: errorPaths.filter { scopedErrors[$0] != nil }
        )
    }

    func validateNested<F: Formulaire>(_ nested: F, field: String) {
        let path = context.appending(field: field)
        clearAllErrors(in: path, includingPath: false)
        let nestedResult = nested.__validator.evaluate(nested, at: path)
        merge(nestedResult)
    }

    func validateNested<F: Formulaire>(_ nested: F?, field: String) {
        let path = context.appending(field: field)
        clearAllErrors(in: path, includingPath: false)
        guard let nested else { return }

        let nestedResult = nested.__validator.evaluate(nested, at: path)
        merge(nestedResult)
    }

    func validateNested<F: Formulaire>(_ nested: IdentifiedArrayOf<F>, field: String) {
        let listPath = context.appending(field: field)
        clearAllErrors(in: listPath, includingPath: false)

        for value in nested {
            let elementPath = listPath.appending(elementID: value.id)
            let nestedResult = value.__validator.evaluate(value, at: elementPath)
            merge(nestedResult)
        }
    }

    private func merge(_ result: ValidationResult) {
        for path in result.errorPaths where !errorPaths.contains(path) {
            errorPaths.append(path)
        }
        errors.merge(result.errors, uniquingKeysWith: { _, new in new })
    }
}
