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
    let pendingCandidates: Binding<[FormulairePath]>
    let scrollProxy: ScrollViewProxy

    func updateRenderedFields(_ fields: [FormulairePath]) {
        renderedFields.wrappedValue = fields

        if let candidate = pendingCandidates.wrappedValue.first, fields.contains(candidate) {
            pendingCandidates.wrappedValue = []
            DispatchQueue.main.async {
                focus.wrappedValue = candidate
            }
            return
        }

        if let focusedField = focus.wrappedValue, !fields.contains(focusedField) {
            focus.wrappedValue = nil
        }
    }

    @discardableResult
    func focus(on field: FormulairePath) -> Bool {
        guard renderedFields.wrappedValue.contains(field) else {
            return false
        }

        pendingCandidates.wrappedValue = []
        scrollProxy.scrollTo(field)
        DispatchQueue.main.async {
            focus.wrappedValue = field
        }
        return true
    }

    func focusFirstError(in result: ValidationResult) {
        attemptFocus(on: result.errorPaths)
    }

    private func attemptFocus(on candidates: [FormulairePath]) {
        guard let candidate = candidates.first else {
            pendingCandidates.wrappedValue = []
            return
        }

        focus.wrappedValue = nil
        pendingCandidates.wrappedValue = candidates
        scrollProxy.scrollTo(candidate, anchor: .center)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard pendingCandidates.wrappedValue.first == candidate else { return }

            if renderedFields.wrappedValue.contains(candidate) {
                pendingCandidates.wrappedValue = []
                focus.wrappedValue = candidate
            } else {
                attemptFocus(on: Array(candidates.dropFirst()))
            }
        }
    }
}
