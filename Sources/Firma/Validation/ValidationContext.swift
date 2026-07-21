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

/// The error-reporting and composition interface for one validation pass.
///
/// Firma creates this value before calling ``Firma/validate(_:)``. Use it
/// only during that callback to attach errors to fields and include nested
/// subjects in the same validation result.
public struct ValidationContext<F> {
    private let subject: F
    private let validator: Validator
    private let path: FirmaPath

    init(subject: F, validator: Validator, path: FirmaPath) {
        self.subject = subject
        self.validator = validator
        self.path = path
    }
}

public extension ValidationContext where F: Firma {
    /// Attaches an error to a field in the current validation pass.
    ///
    /// Adding another error for the same field replaces the earlier error while
    /// preserving that field's position in validation order.
    ///
    /// - Parameters:
    ///   - error: The error associated with the field.
    ///   - field: The generated field metadata to which the error belongs.
    func addError<V>(_ error: any Error, for field: FieldPath<F, V>) {
        let concreteField = F.__fields[keyPath: field]
        validator.addError(error, at: path.appending(field: concreteField.label))
    }

    /// Includes a nested subject's rules in the current validation pass.
    ///
    /// - Parameter nested: The field containing the nested subject.
    func validate<Nested: Firma>(_ nested: FieldPath<F, Nested>) {
        let concreteField = F.__fields[keyPath: nested]
        validator.validateNested(
            concreteField.get(subject),
            at: path.appending(field: concreteField.label)
        )
    }

    /// Includes an optional nested subject's rules when it contains a value.
    ///
    /// An absent value contributes no descendant errors.
    ///
    /// - Parameter nested: The field containing the optional nested subject.
    func validate<Nested: Firma>(_ nested: FieldPath<F, Nested?>) {
        let concreteField = F.__fields[keyPath: nested]
        validator.validateNested(
            concreteField.get(subject),
            at: path.appending(field: concreteField.label)
        )
    }

    /// Includes every identified subject's rules in collection order.
    ///
    /// Each element's actual `Hashable` ID becomes part of its error paths.
    ///
    /// - Parameter nested: The field containing the identified subjects.
    func validate<Nested: Firma>(
        _ nested: FieldPath<F, IdentifiedArrayOf<Nested>>
    ) {
        let concreteField = F.__fields[keyPath: nested]
        validator.validateNested(
            concreteField.get(subject),
            at: path.appending(field: concreteField.label)
        )
    }
}
