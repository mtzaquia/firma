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

/// Stable identity for a field rendered or validated by Formulaire.
///
/// Paths retain the actual `Hashable` identity of list elements. Unlike a path
/// assembled from `hashValue`, unequal element IDs cannot alias one another.
public struct FormulairePath: Hashable, CustomStringConvertible {
    enum Component: Hashable {
        case field(String)
        case element(AnyHashable)
    }

    static let root = FormulairePath(components: [])

    let components: [Component]

    init(components: [Component]) {
        self.components = components
    }

    func appending(field: String) -> FormulairePath {
        FormulairePath(components: components + [.field(field)])
    }

    func appending<ID: Hashable>(elementID: ID) -> FormulairePath {
        FormulairePath(components: components + [.element(AnyHashable(elementID))])
    }

    func isAncestor(of other: FormulairePath) -> Bool {
        other.components.starts(with: components)
    }

    func elementID(directlyUnder ancestor: FormulairePath) -> AnyHashable? {
        guard
            ancestor.isAncestor(of: self),
            components.indices.contains(ancestor.components.count),
            case .element(let id) = components[ancestor.components.count]
        else {
            return nil
        }
        return id
    }

    /// A diagnostic representation suitable for logs and accessibility values.
    /// Identity and equality never depend on this string.
    public var description: String {
        components.reduce(into: "") { result, component in
            switch component {
            case .field(let field):
                if !result.isEmpty {
                    result += "."
                }
                result += field
            case .element(let id):
                result += "[\(String(describing: id.base))]"
            }
        }
    }
}
