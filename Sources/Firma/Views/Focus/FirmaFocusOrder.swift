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

enum FirmaFocusOrder {
    static func reconciling(
        _ snapshot: [FirmaPath],
        with existing: [FirmaPath]
    ) -> [FirmaPath] {
        let snapshot = uniqued(snapshot)
        guard !snapshot.isEmpty else { return existing }

        var result = uniqued(existing)

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

    static func candidates(
        in fields: [FirmaPath],
        current: FirmaPath?,
        direction: FirmaFocusDirection
    ) -> [FirmaPath] {
        guard let current, let index = fields.firstIndex(of: current) else {
            return []
        }

        switch direction {
        case .previous:
            return Array(fields[..<index].reversed())
        case .next:
            let next = fields.index(after: index)
            return next < fields.endIndex ? Array(fields[next...]) : []
        }
    }

    static func reconcilingElements(
        in fields: [FirmaPath],
        under listPath: FirmaPath,
        ids: [AnyHashable]
    ) -> [FirmaPath] {
        let currentIDs = Set(ids)
        let retained = fields.filter { field in
            guard let id = field.elementID(directlyUnder: listPath) else {
                return true
            }
            return currentIDs.contains(id)
        }

        var fieldsByID: [AnyHashable: [FirmaPath]] = [:]
        for field in retained {
            guard let id = field.elementID(directlyUnder: listPath) else { continue }
            fieldsByID[id, default: []].append(field)
        }

        let orderedElementFields = ids.flatMap { fieldsByID[$0] ?? [] }
        let elementIndices = retained.indices.filter {
            retained[$0].elementID(directlyUnder: listPath) != nil
        }
        guard elementIndices.count == orderedElementFields.count else {
            return retained
        }

        var result = retained
        for (index, field) in zip(elementIndices, orderedElementFields) {
            result[index] = field
        }
        return result
    }

    private static func uniqued(_ fields: [FirmaPath]) -> [FirmaPath] {
        var seen: Set<FirmaPath> = []
        return fields.filter { seen.insert($0).inserted }
    }
}

enum FirmaFocusDirection {
    case previous
    case next
}
