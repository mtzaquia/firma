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

/// An immutable snapshot produced by a Formulaire validation pass.
public struct ValidationResult {
    /// Errors keyed by their stable, structured field path.
    public let errors: [FormulairePath: any Error]

    /// Error paths in the order validation produced them.
    ///
    /// Unlike dictionary iteration order, this is stable and suitable for
    /// deciding which invalid field should receive focus first.
    public let errorPaths: [FormulairePath]

    /// `true` when the validation pass produced no errors.
    public var isValid: Bool { errors.isEmpty }

    public init(
        errors: [FormulairePath: any Error] = [:],
        errorPaths: [FormulairePath]? = nil
    ) {
        self.errors = errors
        self.errorPaths = (errorPaths ?? Array(errors.keys)).reduce(into: []) { result, path in
            guard errors[path] != nil, !result.contains(path) else { return }
            result.append(path)
        }
    }

    /// Returns the error attached to an exact field path.
    public subscript(path: FormulairePath) -> (any Error)? {
        errors[path]
    }

    /// Returns all errors attached to a path or any of its descendants.
    public func errors(in path: FormulairePath) -> [FormulairePath: any Error] {
        errors.filter { path.contains($0.key) }
    }
}
