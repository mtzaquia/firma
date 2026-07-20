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

struct FormulaireFieldOrderPreferenceKey: PreferenceKey {
    static var defaultValue: [FormulairePath] = []

    static func reduce(value: inout [FormulairePath], nextValue: () -> [FormulairePath]) {
        for path in nextValue() where !value.contains(path) {
            value.append(path)
        }
    }
}

public extension FormulaireBuilder {
    /// Builds a custom control for a field.
    func control<V, Content: View>(
        for field: FieldPath<F, V>,
        focusable: Bool,
        @ViewBuilder content: (ControlBuilder<F, V>) -> Content
    ) -> some View {
        let concreteField = F.__fields[keyPath: field]
        let fieldPath = path.appending(field: concreteField.label)

        return content(
            ControlBuilder(
                id: fieldPath,
                value: binding(for: field),
                focus: $focus,
                error: validator.errors[fieldPath]
            )
        )
        .id(fieldPath)
        .preference(
            key: FormulaireFieldOrderPreferenceKey.self,
            value: focusable ? [fieldPath] : []
        )
    }

    /// Builds a submit button that validates before running a synchronous action.
    func submitButton(_ label: String, onSubmit: @escaping () -> Void) -> some View {
        submitButton(onSubmit: onSubmit) {
            Text(label)
        }
    }

    /// Builds a submit button with a custom label.
    func submitButton<Label: View>(
        onSubmit: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) -> some View {
        Button {
            let result = validation()
            guard result.isValid else {
                focusFirstError(in: result)
                return
            }
            onSubmit()
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
        Button {
            let result = validation()
            guard result.isValid else {
                focusFirstError(in: result)
                return
            }
            Task { await action() }
        } label: {
            label()
        }
        .bold()
    }

    /// Builds a text field for a textual field.
    func textField(
        for field: FieldPath<F, String>,
        label: String,
        placeholder: String? = nil,
        accessibilityIdentifier: String? = nil
    ) -> some View {
        control(for: field, focusable: true) { builder in
            FormulaireTextField(
                label: Text(verbatim: label),
                prompt: Text(verbatim: placeholder ?? "Enter \(label)"),
                accessibilityIdentifier: accessibilityIdentifier,
                builder: builder
            )
        }
    }

    /// Builds a text field with a custom, localizable label and prompt.
    func textField<Label: View>(
        for field: FieldPath<F, String>,
        prompt: Text? = nil,
        accessibilityIdentifier: String? = nil,
        @ViewBuilder label: () -> Label
    ) -> some View {
        control(for: field, focusable: true) { builder in
            FormulaireTextField(
                label: label(),
                prompt: prompt,
                accessibilityIdentifier: accessibilityIdentifier,
                builder: builder
            )
        }
    }

    /// Builds a toggle for a Boolean field.
    func toggle(
        for field: FieldPath<F, Bool>,
        label: String,
        accessibilityIdentifier: String? = nil
    ) -> some View {
        control(for: field, focusable: false) { builder in
            FormulaireToggle(
                label: Text(verbatim: label),
                accessibilityLabel: Text(verbatim: label),
                accessibilityIdentifier: accessibilityIdentifier,
                builder: builder
            )
        }
    }

    /// Builds a toggle with a custom, localizable label.
    func toggle<Label: View>(
        for field: FieldPath<F, Bool>,
        accessibilityLabel: Text? = nil,
        accessibilityIdentifier: String? = nil,
        @ViewBuilder label: () -> Label
    ) -> some View {
        control(for: field, focusable: false) { builder in
            FormulaireToggle(
                label: label(),
                accessibilityLabel: accessibilityLabel,
                accessibilityIdentifier: accessibilityIdentifier,
                builder: builder
            )
        }
    }

    /// Builds an integer stepper, using SwiftUI's native range-aware behavior.
    func stepper(
        for field: FieldPath<F, Int>,
        label: String,
        step: Int = 1,
        range: ClosedRange<Int>? = nil,
        accessibilityIdentifier: String? = nil
    ) -> some View {
        control(for: field, focusable: false) { builder in
            FormulaireStepper(
                label: Text(verbatim: label),
                step: step,
                range: range,
                accessibilityIdentifier: accessibilityIdentifier,
                builder: builder
            )
        }
    }

    /// Builds an integer stepper with a custom, localizable label.
    func stepper<Label: View>(
        for field: FieldPath<F, Int>,
        step: Int = 1,
        range: ClosedRange<Int>? = nil,
        accessibilityIdentifier: String? = nil,
        @ViewBuilder label: () -> Label
    ) -> some View {
        control(for: field, focusable: false) { builder in
            FormulaireStepper(
                label: label(),
                step: step,
                range: range,
                accessibilityIdentifier: accessibilityIdentifier,
                builder: builder
            )
        }
    }

    /// Displays custom content with all errors belonging to a nested subject.
    func content<N: Formulaire, Content: View>(
        for field: FieldPath<F, N>,
        @ViewBuilder content: (_ errors: [FormulairePath: any Error]) -> Content
    ) -> some View {
        let concreteField = F.__fields[keyPath: field]
        let fieldPath = path.appending(field: concreteField.label)
        return content(validator.result.errors(in: fieldPath))
    }

    /// Displays custom content with the top-level error for an identified list.
    func content<N: Formulaire & Identifiable, Content: View>(
        for field: FieldPath<F, IdentifiedArrayOf<N>>,
        @ViewBuilder content: (_ error: (any Error)?) -> Content
    ) -> some View {
        let concreteField = F.__fields[keyPath: field]
        let fieldPath = path.appending(field: concreteField.label)
        return content(validator.errors[fieldPath])
    }
}

private extension FormulaireBuilder {
    func focusFirstError(in result: ValidationResult) {
        attemptFocus(on: result.errorPaths)
    }

    func attemptFocus(on candidates: [FormulairePath]) {
        guard let candidate = candidates.first else {
            focusCandidates.wrappedValue = []
            return
        }

        focus = nil
        focusCandidates.wrappedValue = candidates
        scrollProxy.scrollTo(candidate, anchor: .center)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard focusCandidates.wrappedValue.first == candidate else { return }

            if renderedFields.wrappedValue.contains(candidate) {
                focusCandidates.wrappedValue = []
                focus = candidate
            } else {
                attemptFocus(on: Array(candidates.dropFirst()))
            }
        }
    }
}

private struct FormulaireTextField<F: Formulaire, Label: View>: View {
    @Environment(\.formulaireStyle) private var style
    let label: Label
    let prompt: Text?
    let accessibilityIdentifier: String?
    let builder: ControlBuilder<F, String>

    var body: some View {
        VStack(alignment: .leading) {
            label
                .foregroundStyle(
                    builder.error != nil
                        ? style.errorColor
                        : (builder.isFocused ? style.focusedLabelColor : style.labelColor)
                )
                .font(.caption.bold())
                .textCase(style.uppercasesTextFieldLabels ? .uppercase : nil)

            textField

            ErrorText(error: builder.error)
        }
    }

    @ViewBuilder
    private var textField: some View {
        if let accessibilityIdentifier {
            TextField(text: builder.$value, prompt: prompt) { label }
                .focused(builder.$focus, equals: builder.id)
                .accessibilityIdentifier(accessibilityIdentifier)
        } else {
            TextField(text: builder.$value, prompt: prompt) { label }
                .focused(builder.$focus, equals: builder.id)
        }
    }
}

private struct FormulaireToggle<F: Formulaire, Label: View>: View {
    @Environment(\.formulaireStyle) private var style
    let label: Label
    let accessibilityLabel: Text?
    let accessibilityIdentifier: String?
    let builder: ControlBuilder<F, Bool>

    var body: some View {
        VStack(alignment: .leading) {
            toggle
            ErrorText(error: builder.error)
        }
    }

    @ViewBuilder
    private var toggle: some View {
        let toggle = Toggle(isOn: builder.$value) {
            label.foregroundStyle(builder.error == nil ? Color.primary : style.errorColor)
        }
        if let accessibilityLabel, let accessibilityIdentifier {
            toggle
                .accessibilityLabel(accessibilityLabel)
                .accessibilityIdentifier(accessibilityIdentifier)
        } else if let accessibilityLabel {
            toggle.accessibilityLabel(accessibilityLabel)
        } else if let accessibilityIdentifier {
            toggle.accessibilityIdentifier(accessibilityIdentifier)
        } else {
            toggle
        }
    }
}

private struct FormulaireStepper<F: Formulaire, Label: View>: View {
    let label: Label
    let step: Int
    let range: ClosedRange<Int>?
    let accessibilityIdentifier: String?
    let builder: ControlBuilder<F, Int>

    var body: some View {
        VStack(alignment: .leading) {
            stepper
            ErrorText(error: builder.error)
        }
    }

    @ViewBuilder
    private var stepper: some View {
        let stepper = Group {
            if let range {
                Stepper(value: builder.$value, in: range, step: step, label: stepperLabel)
            } else {
                Stepper(value: builder.$value, step: step, label: stepperLabel)
            }
        }
        if let accessibilityIdentifier {
            stepper.accessibilityIdentifier(accessibilityIdentifier)
        } else {
            stepper
        }
    }

    private func stepperLabel() -> some View {
        LabeledContent {
            Text(builder.value.formatted())
        } label: {
            label
        }
    }
}
