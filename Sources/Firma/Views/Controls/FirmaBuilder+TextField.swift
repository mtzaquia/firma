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

public extension FirmaBuilder {
    /// Builds a text field for a textual field.
    func textField(
        for field: FieldPath<F, String>,
        label: String,
        placeholder: String? = nil,
        accessibilityIdentifier: String? = nil
    ) -> some View {
        control(for: field, focusable: true) { builder in
            FirmaTextField(
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
            FirmaTextField(
                label: label(),
                prompt: prompt,
                accessibilityIdentifier: accessibilityIdentifier,
                builder: builder
            )
        }
    }
}

private struct FirmaTextField<F: Firma, Label: View>: View {
    @Environment(\.firmaStyle) private var style
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

            FirmaErrorText(error: builder.error)
        }
    }

    private var textField: some View {
        TextField(text: builder.$value, prompt: prompt) { label }
            .focused(builder.$focus, equals: builder.id)
            .firmaAccessibility(identifier: accessibilityIdentifier)
    }
}
