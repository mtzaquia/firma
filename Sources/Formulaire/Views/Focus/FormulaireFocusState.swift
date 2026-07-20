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

@MainActor
@Observable
final class FormulaireFocusState {
    var mountedFields: [FormulairePath] = []
    var focusOrder: [FormulairePath] = []
    var elementOrders: [FormulairePath: [AnyHashable]] = [:]

    @ObservationIgnored
    private var elementOrderObservers: [FormulairePath: FormulaireElementOrderObserver] = [:]

    var pendingRequest: FormulaireFocusRequest?

    @ObservationIgnored
    var pendingTask: Task<Void, Never>?

    @ObservationIgnored
    private var nextRequestID = 0

    func makeRequest(
        candidates: [FormulairePath],
        clearsCurrentFocus: Bool
    ) -> FormulaireFocusRequest {
        nextRequestID += 1
        return FormulaireFocusRequest(
            id: nextRequestID,
            candidates: candidates,
            clearsCurrentFocus: clearsCurrentFocus
        )
    }

    func cancelPendingRequest() {
        pendingTask?.cancel()
        pendingTask = nil
        pendingRequest = nil
    }

    func registerElementOrder(_ elementOrder: FormulaireElementOrder) {
        elementOrderObservers[elementOrder.listPath]?.stop()

        let observer = FormulaireElementOrderObserver()
        elementOrderObservers[elementOrder.listPath] = observer
        observer.start(observing: [elementOrder]) { [weak self] snapshots in
            guard let snapshot = snapshots.first else { return }
            self?.updateElementOrder(snapshot)
        }
    }

    func removeElementOrders(in path: FormulairePath) {
        let paths = elementOrderObservers.keys.filter { path.isAncestor(of: $0) }
        for path in paths {
            elementOrderObservers.removeValue(forKey: path)?.stop()
            elementOrders.removeValue(forKey: path)
        }
        focusOrder = applyingElementOrders(to: focusOrder)
    }

    func reconcileMountedFields(_ fields: [FormulairePath]) {
        mountedFields = fields
        focusOrder = applyingElementOrders(
            to: FormulaireFocusOrder.reconciling(fields, with: focusOrder)
        )
    }

    private func updateElementOrder(_ snapshot: FormulaireElementOrderSnapshot) {
        elementOrders[snapshot.listPath] = snapshot.ids
        pruneRemovedDescendantOrders(
            under: snapshot.listPath,
            currentIDs: Set(snapshot.ids)
        )
        focusOrder = applyingElementOrders(to: focusOrder)
    }

    private func pruneRemovedDescendantOrders(
        under listPath: FormulairePath,
        currentIDs: Set<AnyHashable>
    ) {
        let removedPaths = elementOrderObservers.keys.filter { path in
            guard
                path != listPath,
                let id = path.elementID(directlyUnder: listPath)
            else {
                return false
            }
            return !currentIDs.contains(id)
        }
        for path in removedPaths {
            elementOrderObservers.removeValue(forKey: path)?.stop()
            elementOrders.removeValue(forKey: path)
        }
    }

    private func applyingElementOrders(
        to fields: [FormulairePath]
    ) -> [FormulairePath] {
        elementOrders.reduce(fields) { result, elementOrder in
            FormulaireFocusOrder.reconcilingElements(
                in: result,
                under: elementOrder.key,
                ids: elementOrder.value
            )
        }
    }

    deinit {
        pendingTask?.cancel()
    }
}

struct FormulaireFocusRequest {
    let id: Int
    var candidates: [FormulairePath]
    let clearsCurrentFocus: Bool
}
