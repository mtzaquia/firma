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
    let renderedFields: Binding<[FormulairePath]>
    let focusOrder: Binding<[FormulairePath]>
    let pendingCandidates: Binding<[FormulairePath]>
    let scrollProxy: ScrollViewProxy

    func updateRenderedFields(_ fields: [FormulairePath]) {
        renderedFields.wrappedValue = fields
        let reconciledOrder = FormulaireFocusOrder.reconciling(
            fields,
            with: focusOrder.wrappedValue
        )
        if reconciledOrder != focusOrder.wrappedValue {
            focusOrder.wrappedValue = reconciledOrder
        }
    }

    @discardableResult
    func focus(on field: FormulairePath) -> Bool {
        guard focusOrder.wrappedValue.contains(field) else {
            return false
        }

        attemptFocus(on: [field], clearingCurrentFocus: true)
        return true
    }

    func move(to field: FormulairePath?) {
        guard let field else { return }
        attemptFocus(on: [field], clearingCurrentFocus: false)
    }

    func focusFirstError(in result: ValidationResult) {
        attemptFocus(on: result.errorPaths, clearingCurrentFocus: true)
    }

    private func attemptFocus(
        on candidates: [FormulairePath],
        clearingCurrentFocus: Bool
    ) {
        guard let candidate = candidates.first else {
            pendingCandidates.wrappedValue = []
            return
        }

        if clearingCurrentFocus {
            focus.wrappedValue = nil
        }
        pendingCandidates.wrappedValue = candidates
        scrollProxy.scrollTo(candidate, anchor: .center)

        // A lazy Form can advertise a preference before the destination's
        // native control is ready to accept focus. Give scrolling and mounting
        // one layout pass before assigning the FocusState value.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard pendingCandidates.wrappedValue.first == candidate else { return }

            if renderedFields.wrappedValue.contains(candidate) {
                pendingCandidates.wrappedValue = []
                focus.wrappedValue = candidate
            } else {
                focusOrder.wrappedValue.removeAll { $0 == candidate }
                attemptFocus(
                    on: Array(candidates.dropFirst()),
                    clearingCurrentFocus: clearingCurrentFocus
                )
            }
        }
    }
}
