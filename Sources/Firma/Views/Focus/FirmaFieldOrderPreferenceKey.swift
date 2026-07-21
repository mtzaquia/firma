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

struct FirmaFieldOrderEntry: Equatable {
    let path: FirmaPath
    let frame: CGRect
}

struct FirmaFieldOrderPreferenceKey: PreferenceKey {
    static var defaultValue: [FirmaFieldOrderEntry] = []

    static func reduce(
        value: inout [FirmaFieldOrderEntry],
        nextValue: () -> [FirmaFieldOrderEntry]
    ) {
        var indices: [FirmaPath: Int] = [:]
        for index in value.indices {
            indices[value[index].path] = index
        }
        for entry in nextValue() {
            if let index = indices[entry.path] {
                value[index] = entry
            } else {
                indices[entry.path] = value.endIndex
                value.append(entry)
            }
        }
    }

    static func orderedPaths(from entries: [FirmaFieldOrderEntry]) -> [FirmaPath] {
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
