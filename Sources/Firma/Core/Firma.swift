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
/// A macro that allows a class to be used as the subject of ``FirmaContent``.
public macro FormObject() = #externalMacro(module: "FormObjectMacros", type: "FormObjectMacro")

/// The protocol allowing a class to be used as the subject of ``FirmaContent``.
/// - Important: You don't conform to this protocol directly. Use the ``FormObject()`` macro instead.
public protocol Firma {
    /// A function implementing validation logic for this subject.
    ///
    /// You can use ``addError(_:for:)`` to tag fields with errors, and/or ``validate(_:)`` on nested subjects to reuse their individual validation logic.
    ///
    /// ```swift
    /// @Observable @FormObject
    /// final class MyForm {
    ///   var name: String
    ///   var address: Address
    ///
    ///   func validate() {
    ///     if name.isEmpty {
    ///       addError(RequiredFieldMissing(), for: \.name)
    ///     }
    ///  
    ///     validate(\.address)
    ///   }
    /// }
    /// ```
    func validate()

    associatedtype Fields

    /// **[Internal use]** You do not interact with this property directly.
    static var __fields: Fields { get }

    /// **[Internal use]** You do not interact with this property directly.
    var __validator: Validator { get }
}
