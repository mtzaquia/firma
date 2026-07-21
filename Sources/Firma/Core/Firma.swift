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

@attached(member, names: named(Fields), named(__fields), named(__validator))
@attached(extension, conformances: Firma)
/// A macro that allows an observable class to be used as the subject of ``FirmaContent``.
///
/// The macro generates type-safe field metadata, validation storage, and
/// ``Firma`` conformance. Public writable fields require explicit type
/// annotations so their generated metadata can use the same access level.
public macro FormModel() = #externalMacro(module: "FormModelMacros", type: "FormModelMacro")

/// The protocol allowing a class to be used as the subject of ``FirmaContent``.
///
/// Use the ``FormModel()`` macro instead of declaring conformance directly.
public protocol Firma {
    /// Adds this subject's validation errors to a validation pass.
    ///
    /// Use the supplied ``ValidationContext`` to attach errors and compose the
    /// rules of nested subjects. Firma calls this method during
    /// ``Firma/validate()``; do not invoke it directly to start validation.
    ///
    /// ```swift
    /// @Observable @FormModel
    /// final class MyForm {
    ///   var name: String
    ///   var address: Address
    ///
    ///   func validate(_ validation: ValidationContext<MyForm>) {
    ///     if name.isEmpty {
    ///       validation.addError(RequiredFieldMissing(), for: \.name)
    ///     }
    ///  
    ///     validation.validate(\.address)
    ///   }
    /// }
    /// ```
    ///
    /// - Parameter validation: The context for reporting errors and validating
    ///   nested subjects in the current pass.
    func validate(_ validation: ValidationContext<Self>)

    associatedtype Fields

    /// **[Internal use]** You do not interact with this property directly.
    static var __fields: Fields { get }

    /// **[Internal use]** You do not interact with this property directly.
    var __validator: Validator { get }
}
