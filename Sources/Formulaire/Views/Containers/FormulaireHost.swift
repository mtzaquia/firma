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

struct FormulaireHost<F: Formulaire, Content: View>: View {
    @Binding var subject: F
    @FocusState private var focus: FormulairePath?
    @State private var renderedFields: [FormulairePath] = []
    @State private var focusOrder: [FormulairePath] = []
    @State private var focusCandidates: [FormulairePath] = []

    @ViewBuilder let content: (FormulaireBuilder<F>) -> Content

    var body: some View {
        let root = $subject
        ScrollViewReader { proxy in
            let focusCoordinator = FormulaireFocusCoordinator(
                focus: $focus,
                renderedFields: $renderedFields,
                focusOrder: $focusOrder,
                pendingCandidates: $focusCandidates,
                scrollProxy: proxy
            )

            content(
                FormulaireBuilder(
                    formulaire: root,
                    focusCoordinator: focusCoordinator,
                    validator: root.wrappedValue.__validator,
                    path: .root,
                    validateFunction: { root.wrappedValue.runValidation() }
                )
            )
            .onPreferenceChange(FormulaireFieldOrderPreferenceKey.self) { entries in
                focusCoordinator.updateRenderedFields(
                    FormulaireFieldOrderPreferenceKey.orderedPaths(from: entries)
                )
            }
            .formulaireKeyboardToolbar(focusCoordinator)
        }
    }
}
