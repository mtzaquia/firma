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

/// A convenience container that renders Formulaire content inside a SwiftUI `Form`.
public struct FormulaireView<F: Formulaire, C: View>: View {
    @Binding private var subject: F
    private let builder: (FormulaireBuilder<F>) -> C

    public var body: some View {
        FormulaireHost(subject: $subject) { form in
            Form {
                builder(form)
            }
        }
    }

    public init(
        editing subject: Binding<F>,
        @ViewBuilder builder: @escaping (FormulaireBuilder<F>) -> C
    ) {
        self._subject = subject
        self.builder = builder
    }

    static func nextFocusId(
        in fields: [FormulairePath],
        current: FormulairePath?
    ) -> FormulairePath? {
        FormulaireFocusOrder.next(in: fields, current: current)
    }

    static func previousFocusId(
        in fields: [FormulairePath],
        current: FormulairePath?
    ) -> FormulairePath? {
        FormulaireFocusOrder.previous(in: fields, current: current)
    }
}

/// Hosts Formulaire controls without imposing a `Form`, `List`, or scroll layout.
///
/// Use this variant when an app needs to supply its own container:
///
/// ```swift
/// FormulaireContent(editing: $model) { form in
///   ScrollView {
///     VStack { form.textField(for: \.name, label: "Name") }
///   }
/// }
/// ```
public struct FormulaireContent<F: Formulaire, C: View>: View {
    @Binding private var subject: F
    private let builder: (FormulaireBuilder<F>) -> C

    public var body: some View {
        FormulaireHost(subject: $subject, content: builder)
    }

    public init(
        editing subject: Binding<F>,
        @ViewBuilder builder: @escaping (FormulaireBuilder<F>) -> C
    ) {
        self._subject = subject
        self.builder = builder
    }
}

private struct FormulaireHost<F: Formulaire, Content: View>: View {
    @Binding var subject: F
    @FocusState private var focus: FormulairePath?
    @State private var renderedFields: [FormulairePath] = []
    @State private var focusCandidates: [FormulairePath] = []

    @ViewBuilder let content: (FormulaireBuilder<F>) -> Content

    var body: some View {
        let root = $subject
        ScrollViewReader { proxy in
            content(
                FormulaireBuilder(
                    formulaire: root,
                    scrollProxy: proxy,
                    focus: $focus,
                    renderedFields: $renderedFields,
                    focusCandidates: $focusCandidates,
                    validator: root.wrappedValue.__validator,
                    path: .root,
                    validateFunction: { root.wrappedValue.runValidation() }
                )
            )
            .onPreferenceChange(FormulaireFieldOrderPreferenceKey.self) { fields in
                renderedFields = fields
                if let candidate = focusCandidates.first, fields.contains(candidate) {
                    focusCandidates = []
                    DispatchQueue.main.async {
                        focus = candidate
                    }
                    return
                }
                if let focus, !fields.contains(focus) {
                    self.focus = nil
                }
            }
            .formulaireKeyboardToolbar(
                focus: $focus,
                renderedFields: renderedFields,
                proxy: proxy
            )
        }
    }
}

enum FormulaireFocusOrder {
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

extension View {
    @ViewBuilder
    func formulaireKeyboardToolbar(
        focus: FocusState<FormulairePath?>.Binding,
        renderedFields: [FormulairePath],
        proxy: ScrollViewProxy
    ) -> some View {
        #if os(iOS)
        let info = Bundle.main.infoDictionary
        if #available(iOS 26, *), (info?["UIDesignRequiresCompatibility"] as? Bool) != true {
            safeAreaBar(edge: .bottom) {
                ZStack {
                    if focus.wrappedValue != nil {
                        FormulaireKeyboardControls(
                            focus: focus,
                            renderedFields: renderedFields,
                            proxy: proxy,
                            iconOnlyDoneButton: true
                        )
                        .padding()
                        .glassEffect(.regular, in: .capsule)
                        .transition(.blurReplace)
                    }
                }
                .padding([.horizontal, .bottom])
                .animation(.snappy, value: focus.wrappedValue != nil)
            }
        } else {
            toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    FormulaireKeyboardControls(
                        focus: focus,
                        renderedFields: renderedFields,
                        proxy: proxy,
                        iconOnlyDoneButton: false
                    )
                }
            }
        }
        #else
        self
        #endif
    }
}
