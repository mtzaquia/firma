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

struct FormulaireAsyncSubmitButton<F: Formulaire, Label: View>: View {
    let builder: FormulaireBuilder<F>
    let action: @MainActor () async -> Void
    let label: Label

    @State private var submissionTask: Task<Void, Never>?
    @State private var submissionGeneration = 0

    var body: some View {
        Button {
            guard submissionTask == nil, builder.prepareForSubmission() else { return }
            submissionGeneration += 1
            let generation = submissionGeneration
            submissionTask = Task { @MainActor in
                await action()
                guard submissionGeneration == generation else { return }
                submissionTask = nil
            }
        } label: {
            label
        }
        .bold()
        .disabled(submissionTask != nil)
        .onDisappear {
            submissionGeneration += 1
            submissionTask?.cancel()
            submissionTask = nil
        }
    }
}
