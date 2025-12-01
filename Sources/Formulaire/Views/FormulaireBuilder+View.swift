//
//  Copyright (c) 2025 @mtzaquia
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
    /// Builds a control for editing one of the fields from the subject.
    ///
    /// - Parameters:
    ///   - field: The field path that is to be mutated in the subject.
    ///   - focusable: A flag indicating whether this control should be part of the focus system.
    ///   - content: The view for the control, built using a ``ControlBuilder``.
    func control<V, Content: View>(
        for field: FieldPath<F, V>,
        focusable: Bool,
        @ViewBuilder content: (ControlBuilder<F, V>) -> Content
    ) -> some View {
        let concreteField = F.__fields[keyPath: field]

        let fieldId = [parent, concreteField.label].compactMap(\.self).joined(separator: ".")
        if focusable {
            renderedFields.value.append(fieldId)
        }

        return content(
            ControlBuilder(
                id: fieldId,
                value: $formulaire[field: concreteField],
                focus: $focus,
                error: formulaire.__validator.errors[fieldId]
            )
        )
        .id(fieldId)
    }

    /// Builds a submit button for the form.
    ///
    /// When using the submit button, the form is validated automatically. If there are any errors, the first focusable field with an error becomes focused
    /// automatically.
    ///
    /// - SeeAlso: ``FormulaireBuilder/validate()``, for validating forms and applying your own custom logic.
    ///
    /// - Parameters:
    ///   - label: The button label.
    ///   - onSubmit: The action to be taken if the form is successfuly validated.
    func submitButton(_ label: String, onSubmit: @escaping () -> Void) -> some View {
        Button(label) {
            if validate() {
                onSubmit()
            } else {
                if let firstError = renderedFields.value.first(where: { formulaire.__validator.errors[$0] != nil }) {
                    scrollProxy.scrollTo(firstError)
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        focus = firstError
                    }
                }
            }
        }
        .bold()
    }

    /// Builds a text field for editing textual fields.
    ///
    /// - Parameters:
    ///   - field: The field path that is to be mutated in the subject.
    ///   - label: The user-facing label for the field.
    func textField(for field: FieldPath<F, String>, label: String, placeholder: String? = nil) -> some View {
        control(for: field, focusable: true) { builder in
            VStack(alignment: .leading) {
                Text(label)
                    .foregroundStyle(
                        builder.error != nil ? AnyShapeStyle(.red) : (
                            builder.isFocused ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary)
                        )
                    )
                    .font(.caption.bold())
                    .textCase(.uppercase)
                
                TextField(
                    label,
                    text: builder.$value,
                    prompt: Text(placeholder ?? "Enter \(label.localizedCapitalized)")
                )
                .focused(builder.$focus, equals: builder.id)

                ErrorText(error: builder.error)
            }
        }
    }

    /// Builds a toggle for editing boolean fields.
    ///
    /// - Parameters:
    ///   - field: The field path that is to be mutated in the subject.
    ///   - label: The user-facing label for the field.
    func toggle(for field: FieldPath<F, Bool>, label: String) -> some View {
        control(for: field, focusable: false) { builder in
            VStack(alignment: .leading) {
                Toggle(isOn: builder.$value) {
                    Text(label)
                        .foregroundStyle(builder.error != nil ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
                }

                ErrorText(error: builder.error)
            }
        }
    }

    /// Builds a stepper for editing numberic fields without decimals.
    ///
    /// - Parameters:
    ///   - field: The field path that is to be mutated in the subject.
    ///   - label: The user-facing label for the field.
    ///   - step: The amount by the which the value changes when up or down are pressed. Defaults to 1.
    ///   - range: The allowed range for the number. Optional.
    func stepper(
        for field: FieldPath<F, Int>,
        label: String,
        step: Int = 1,
        range: ClosedRange<Int>? = nil
    ) -> some View {
        control(for: field, focusable: false) { builder in
            VStack(alignment: .leading) {
                Stepper(
                    value: builder.$value,
                    step: step
                ) {
                    Text(label)
                    Text(builder.value.formatted())
                        .monospaced()
                }

                ErrorText(error: builder.error)
            }
            .onChange(of: builder.value) { _, new in
                guard let range else { return }
                builder.value = min(max(new, range.lowerBound), range.upperBound)
            }
        }
    }

    /// Allows the user to build some visual content on the form for nested formulaire subjects, while conveniently providing
    /// collected errors for that particular subject.
    ///
    /// - Parameters:
    ///   - field: The field path of the relevant value.
    ///   - content: The view to be displayed, provided with a list of errors matching the field.
    func content<N: Formulaire, Content: View>(
        for field: FieldPath<F, N>,
        @ViewBuilder content: (_ errors: [String: Error]) -> Content
    ) -> some View {
        let concreteField = F.__fields[keyPath: field]

        return content(formulaire.__validator.errors.filter { key, _ in key.contains("\(concreteField.label).") })
    }

    /// Allows the user to build some visual content on the form for nested lists of formulaire subjects, while conveniently providing the top-level error
    /// collected for that particular list.
    ///
    /// - Parameters:
    ///   - field: The field path of the relevant list.
    ///   - content: The view to be displayed, provided with the top-level error matching the list.
    func content<N: Formulaire & Identifiable, Content: View>(
        for field: FieldPath<F, IdentifiedArrayOf<N>>,
        @ViewBuilder content: (_ error: Error?) -> Content
    ) -> some View {
        let concreteField = F.__fields[keyPath: field]
        return content(formulaire.__validator.errors[concreteField.label])
    }
}

