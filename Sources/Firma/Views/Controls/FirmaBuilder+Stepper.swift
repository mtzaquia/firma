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
    /// Builds an integer stepper, using SwiftUI's native range-aware behavior.
    func stepper(
        for field: FieldPath<F, Int>,
        label: String,
        step: Int = 1,
        range: ClosedRange<Int>? = nil,
        accessibilityIdentifier: String? = nil
    ) -> some View {
        control(for: field, focusable: false) { builder in
            FirmaStepper(
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
            FirmaStepper(
                label: label(),
                step: step,
                range: range,
                accessibilityIdentifier: accessibilityIdentifier,
                builder: builder
            )
        }
    }
}

private struct FirmaStepper<F: Firma, Label: View>: View {
    let label: Label
    let step: Int
    let range: ClosedRange<Int>?
    let accessibilityIdentifier: String?
    let builder: ControlBuilder<F, Int>

    var body: some View {
        VStack(alignment: .leading) {
            stepper
            FirmaErrorText(error: builder.error)
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
        stepper.firmaAccessibility(identifier: accessibilityIdentifier)
    }

    private func stepperLabel() -> some View {
        LabeledContent {
            Text(builder.value.formatted())
        } label: {
            label
        }
    }
}
