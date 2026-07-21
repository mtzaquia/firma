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

/// An immutable snapshot produced by a Firma validation pass.
public struct ValidationResult {
    /// Errors keyed by their stable, structured field path.
    public let errors: [FirmaPath: any Error]

    /// Error paths in the order supplied by the validation pass.
    ///
    /// Unlike dictionary iteration order, this is stable and suitable for
    /// deciding which invalid field should receive focus first.
    public let errorPaths: [FirmaPath]

    /// `true` when the validation pass produced no errors.
    public var isValid: Bool { errors.isEmpty }

    /// Creates a validation snapshot.
    ///
    /// Pass `errorPaths` whenever ordering is meaningful. When omitted, paths
    /// follow the dictionary's iteration order and must not be used to choose a
    /// first field.
    public init(
        errors: [FirmaPath: any Error] = [:],
        errorPaths: [FirmaPath]? = nil
    ) {
        self.errors = errors
        var seen: Set<FirmaPath> = []
        self.errorPaths = (errorPaths ?? Array(errors.keys)).reduce(into: []) { result, path in
            guard errors[path] != nil, seen.insert(path).inserted else { return }
            result.append(path)
        }
    }

    /// Returns the error attached to an exact field path.
    public subscript(path: FirmaPath) -> (any Error)? {
        errors[path]
    }

    /// Returns all errors attached to a path or any of its descendants.
    public func errors(in path: FirmaPath) -> [FirmaPath: any Error] {
        errors.filter { path.isAncestor(of: $0.key) }
    }
}
