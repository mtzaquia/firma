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

struct FormulaireFieldOrderEntry: Equatable {
    let path: FormulairePath
    let frame: CGRect
}

struct FormulaireFieldOrderPreferenceKey: PreferenceKey {
    static var defaultValue: [FormulaireFieldOrderEntry] = []

    static func reduce(
        value: inout [FormulaireFieldOrderEntry],
        nextValue: () -> [FormulaireFieldOrderEntry]
    ) {
        for entry in nextValue() {
            if let index = value.firstIndex(where: { $0.path == entry.path }) {
                value[index] = entry
            } else {
                value.append(entry)
            }
        }
    }

    static func orderedPaths(from entries: [FormulaireFieldOrderEntry]) -> [FormulairePath] {
        entries
            .sorted { lhs, rhs in
                if abs(lhs.frame.minY - rhs.frame.minY) > 0.5 {
                    return lhs.frame.minY < rhs.frame.minY
                }
                return lhs.frame.minX < rhs.frame.minX
            }
            .map(\.path)
    }
}
