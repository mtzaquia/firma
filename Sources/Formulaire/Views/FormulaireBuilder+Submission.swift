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

public extension FormulaireBuilder {
    /// Builds a submit button that validates before running a synchronous action.
    func submitButton(_ label: String, onSubmit: @escaping () -> Void) -> some View {
        submitButton(onSubmit: onSubmit) {
            Text(verbatim: label)
        }
    }

    /// Builds a submit button with a custom label.
    func submitButton<Label: View>(
        onSubmit: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) -> some View {
        Button {
            performValidated(onSubmit)
        } label: {
            label()
        }
        .bold()
    }

    /// Builds a submit button that supports asynchronous successful submission.
    func asyncSubmitButton(
        _ label: String,
        action: @escaping @MainActor () async -> Void
    ) -> some View {
        asyncSubmitButton(action: action) {
            Text(verbatim: label)
        }
    }

    /// Builds a submit button that supports asynchronous successful submission.
    func asyncSubmitButton<Label: View>(
        action: @escaping @MainActor () async -> Void,
        @ViewBuilder label: () -> Label
    ) -> some View {
        FormulaireAsyncSubmitButton(
            builder: self,
            action: action,
            label: label()
        )
    }

}

extension FormulaireBuilder {
    func prepareForSubmission() -> Bool {
        let result = validation()
        guard result.isValid else {
            focusCoordinator.focusFirstError(in: result)
            return false
        }
        return true
    }

    private func performValidated(_ action: () -> Void) {
        guard prepareForSubmission() else { return }
        action()
    }
}
