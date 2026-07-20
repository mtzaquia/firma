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

enum FormulaireFocusOrder {
    static func reconciling(
        _ snapshot: [FormulairePath],
        with existing: [FormulairePath]
    ) -> [FormulairePath] {
        let snapshot = snapshot.reduce(into: [FormulairePath]()) { fields, path in
            if !fields.contains(path) {
                fields.append(path)
            }
        }
        guard !snapshot.isEmpty else { return existing }

        var result = existing.reduce(into: [FormulairePath]()) { fields, path in
            if !fields.contains(path) {
                fields.append(path)
            }
        }

        let snapshotSet = Set(snapshot)
        let visibleIndices = result.indices.filter { snapshotSet.contains(result[$0]) }
        if let first = visibleIndices.first, let last = visibleIndices.last, first < last {
            result = result.enumerated().compactMap { index, path in
                guard index < first || index > last || snapshotSet.contains(path) else {
                    return nil
                }
                return path
            }
        }

        let occupiedIndices = result.indices.filter { snapshotSet.contains(result[$0]) }
        let existingSnapshot = snapshot.filter { result.contains($0) }
        for (index, path) in zip(occupiedIndices, existingSnapshot) {
            result[index] = path
        }

        for (snapshotIndex, path) in snapshot.enumerated() where !result.contains(path) {
            let previous = snapshot[..<snapshotIndex].reversed().first { result.contains($0) }
            let following = snapshot[snapshot.index(after: snapshotIndex)...].first { result.contains($0) }

            if let previous, let index = result.firstIndex(of: previous) {
                result.insert(path, at: result.index(after: index))
            } else if let following, let index = result.firstIndex(of: following) {
                result.insert(path, at: index)
            } else {
                result.append(path)
            }
        }

        return result
    }

    static func previous(
        in fields: [FormulairePath],
        current: FormulairePath?
    ) -> FormulairePath? {
        guard let current, let index = fields.firstIndex(of: current), index > fields.startIndex else {
            return nil
        }
        return fields[fields.index(before: index)]
    }

    static func next(
        in fields: [FormulairePath],
        current: FormulairePath?
    ) -> FormulairePath? {
        guard let current, let index = fields.firstIndex(of: current) else {
            return nil
        }
        let next = fields.index(after: index)
        return next < fields.endIndex ? fields[next] : nil
    }
}
