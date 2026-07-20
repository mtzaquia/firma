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

import Observation

/// Observable validation state owned by a ``Formulaire`` subject.
///
/// Validation passes are started by ``Formulaire/runValidation()`` or a
/// ``FormulaireBuilder``. Calling a model's rule-producing `validate()` method
/// directly intentionally does not start a new pass.
@Observable
public final class Validator {
    @ObservationIgnored
    private var context: FormulairePath = .root

    private var state = FormulaireValidationState()

    public var errors: [FormulairePath: any Error] {
        state.errors
    }

    /// The current validation snapshot.
    public var result: ValidationResult {
        state.result
    }

    /// **[Internal use]** Formulaire models receive an instance from the macro.
    public init() {}

    func addError(_ error: any Error, for field: String) {
        state.add(error, at: context.appending(field: field))
    }

    func removeErrors(in path: FormulairePath, includingPath: Bool = true) {
        state.removeErrors(in: path, includingPath: includingPath)
    }

    func evaluate<F: Formulaire>(_ subject: F, at path: FormulairePath) -> ValidationResult {
        state.reset()
        withContext(path) {
            subject.validate()
        }
        return result
    }

    func replaceValidation<F: Formulaire>(of subject: F, at path: FormulairePath) -> ValidationResult {
        removeErrors(in: path, includingPath: false)

        let childResult: ValidationResult
        if subject.__validator === self {
            let preserved = state
            childResult = evaluate(subject, at: path)
            state = preserved
        } else {
            childResult = subject.__validator.evaluate(subject, at: path)
        }
        state.merge(childResult)

        return state.result(in: path)
    }

    func validateNested<F: Formulaire>(_ nested: F, field: String) {
        let path = context.appending(field: field)
        validateNested([(nested, path)], in: path)
    }

    func validateNested<F: Formulaire>(_ nested: F?, field: String) {
        let path = context.appending(field: field)
        validateNested(nested.map { [($0, path)] } ?? [], in: path)
    }

    func validateNested<F: Formulaire>(_ nested: IdentifiedArrayOf<F>, field: String) {
        let listPath = context.appending(field: field)
        validateNested(
            nested.map { ($0, listPath.appending(elementID: $0.id)) },
            in: listPath
        )
    }

    private func validateNested<F: Formulaire>(
        _ subjects: [(F, FormulairePath)],
        in containerPath: FormulairePath
    ) {
        removeErrors(in: containerPath, includingPath: false)
        for (subject, subjectPath) in subjects {
            state.merge(subject.__validator.evaluate(subject, at: subjectPath))
        }
    }

    private func withContext<T>(
        _ path: FormulairePath,
        perform operation: () throws -> T
    ) rethrows -> T {
        let previousContext = context
        context = path
        defer { context = previousContext }
        return try operation()
    }
}
