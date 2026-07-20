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
            FormulaireErrorText(error: builder.error)
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
