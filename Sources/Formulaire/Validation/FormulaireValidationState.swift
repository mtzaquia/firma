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

struct FormulaireValidationState {
    private(set) var errors: [FormulairePath: any Error] = [:]
    private(set) var errorPaths: [FormulairePath] = []

    var result: ValidationResult {
        ValidationResult(errors: errors, errorPaths: errorPaths)
    }

    mutating func reset() {
        errors.removeAll()
        errorPaths.removeAll()
    }

    mutating func add(_ error: any Error, at path: FormulairePath) {
        if errors[path] == nil {
            errorPaths.append(path)
        }
        errors[path] = error
    }

    mutating func removeErrors(
        in path: FormulairePath,
        includingPath: Bool
    ) {
        errors = errors.filter { key, _ in
            if key == path {
                return !includingPath
            }
            return !path.isAncestor(of: key)
        }
        errorPaths.removeAll { errors[$0] == nil }
    }

    mutating func merge(_ result: ValidationResult) {
        var knownPaths = Set(errorPaths)
        for path in result.errorPaths where knownPaths.insert(path).inserted {
            errorPaths.append(path)
        }
        errors.merge(result.errors, uniquingKeysWith: { _, new in new })
    }

    func result(in path: FormulairePath) -> ValidationResult {
        let scopedErrors = errors.filter { path.isAncestor(of: $0.key) }
        return ValidationResult(
            errors: scopedErrors,
            errorPaths: errorPaths.filter { scopedErrors[$0] != nil }
        )
    }
}
