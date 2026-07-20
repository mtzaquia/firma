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

struct FormulaireFocusCoordinator {
    let focus: FocusState<FormulairePath?>.Binding
    let state: FormulaireFocusState
    let scrollProxy: ScrollViewProxy

    func updateMountedFields(_ fields: [FormulairePath]) {
        state.reconcileMountedFields(fields)

        guard
            let request = state.pendingRequest,
            let candidate = request.candidates.first,
            fields.contains(candidate)
        else {
            return
        }

        scheduleFocusAssignment(to: candidate, requestID: request.id)
    }

    @discardableResult
    func focus(on field: FormulairePath) -> Bool {
        requestFocus(on: [field], clearingCurrentFocus: true)
        return true
    }

    func canMove(_ direction: FormulaireFocusDirection) -> Bool {
        state.pendingRequest == nil && !navigationCandidates(in: direction).isEmpty
    }

    func move(_ direction: FormulaireFocusDirection) {
        guard state.pendingRequest == nil else { return }
        requestFocus(
            on: navigationCandidates(in: direction),
            clearingCurrentFocus: false
        )
    }

    func focusFirstError(in result: ValidationResult) {
        requestFocus(on: result.errorPaths, clearingCurrentFocus: true)
    }

    func registerElementOrder(_ elementOrder: FormulaireElementOrder) {
        Task { @MainActor in
            state.registerElementOrder(elementOrder)
        }
    }

    func removeElementOrders(in path: FormulairePath) {
        Task { @MainActor in
            state.removeElementOrders(in: path)
        }
    }

    func dismiss() {
        state.cancelPendingRequest()
        focus.wrappedValue = nil
    }

    private func navigationCandidates(
        in direction: FormulaireFocusDirection
    ) -> [FormulairePath] {
        FormulaireFocusOrder.candidates(
            in: state.focusOrder,
            current: focus.wrappedValue,
            direction: direction
        )
    }

    private func requestFocus(
        on candidates: [FormulairePath],
        clearingCurrentFocus: Bool
    ) {
        state.cancelPendingRequest()
        guard !candidates.isEmpty else { return }

        let request = state.makeRequest(
            candidates: candidates,
            clearsCurrentFocus: clearingCurrentFocus
        )
        if request.clearsCurrentFocus {
            focus.wrappedValue = nil
        }
        state.pendingRequest = request
        advance(requestID: request.id)
    }

    private func advance(requestID: Int) {
        guard
            let request = state.pendingRequest,
            request.id == requestID,
            let candidate = request.candidates.first
        else {
            state.cancelPendingRequest()
            return
        }

        scrollProxy.scrollTo(candidate, anchor: .center)

        if state.mountedFields.contains(candidate) {
            scheduleFocusAssignment(to: candidate, requestID: requestID)
        } else {
            scheduleStaleCandidateFallback(candidate, requestID: requestID)
        }
    }

    private func scheduleFocusAssignment(
        to candidate: FormulairePath,
        requestID: Int
    ) {
        state.pendingTask?.cancel()
        state.pendingTask = Task { @MainActor in
            // The mounted-field preference is produced during layout. Yield so
            // the native control can finish joining the focus hierarchy.
            await Task.yield()
            guard
                !Task.isCancelled,
                state.pendingRequest?.id == requestID,
                state.pendingRequest?.candidates.first == candidate,
                state.mountedFields.contains(candidate)
            else {
                return
            }

            state.cancelPendingRequest()
            focus.wrappedValue = candidate
        }
    }

    private func scheduleStaleCandidateFallback(
        _ candidate: FormulairePath,
        requestID: Int
    ) {
        state.pendingTask?.cancel()
        state.pendingTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard
                !Task.isCancelled,
                state.pendingRequest?.id == requestID,
                state.pendingRequest?.candidates.first == candidate
            else {
                return
            }

            state.focusOrder.removeAll { $0 == candidate }
            state.pendingRequest?.candidates.removeFirst()
            advance(requestID: requestID)
        }
    }
}
