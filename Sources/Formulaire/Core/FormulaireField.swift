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

/// An indirect reference for the key path of a ``Formulaire`` field.
public typealias FieldPath<F: Formulaire, V> = KeyPath<F.Fields, FormulaireField<F, V>>

/// An abstraction of a Formulaire field for a given property of a ``Formulaire`` subject.
public struct FormulaireField<Root, Value>: Hashable {
    let label: String
    let get: (Root) -> Value
    let set: (Root, Value) -> Void

    /// **[Internal use]** You do not instantiate this type directly.
    public init(label: String, keyPath: ReferenceWritableKeyPath<Root, Value>) {
        self.label = label
        self.get = { root in root[keyPath: keyPath] }
        self.set = { root, newValue in root[keyPath: keyPath] = newValue }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(label)
    }
}

public func == <R, V>(lhs: FormulaireField<R, V>, rhs: FormulaireField<R, V>) -> Bool {
    lhs.label == rhs.label
}
