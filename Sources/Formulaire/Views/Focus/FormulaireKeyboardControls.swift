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

#if os(iOS)
struct FormulaireKeyboardControls: View {
    let focusCoordinator: FormulaireFocusCoordinator
    let iconOnlyDoneButton: Bool

    var body: some View {
        HStack(spacing: iconOnlyDoneButton ? 24 : 12) {
            Button("Previous", systemImage: "chevron.up") {
                focusCoordinator.move(to: previousField)
            }
            .labelStyle(.iconOnly)
            .disabled(previousField == nil)

            Button("Next", systemImage: "chevron.down") {
                focusCoordinator.move(to: nextField)
            }
            .labelStyle(.iconOnly)
            .disabled(nextField == nil)

            Spacer(minLength: 0)

            Button("Done", systemImage: "checkmark") {
                focusCoordinator.focus.wrappedValue = nil
            }
                .labelStyle(iconOnlyDoneButton ? AnyLabelStyle(.iconOnly) : AnyLabelStyle(.titleOnly))
                .bold()
        }
        .contentShape(Rectangle())
        .imageScale(.large)
        .fontWeight(.medium)
    }

    private var previousField: FormulairePath? {
        FormulaireFocusOrder.previous(
            in: focusCoordinator.focusOrder.wrappedValue,
            current: focusCoordinator.focus.wrappedValue
        )
    }

    private var nextField: FormulairePath? {
        FormulaireFocusOrder.next(
            in: focusCoordinator.focusOrder.wrappedValue,
            current: focusCoordinator.focus.wrappedValue
        )
    }
}

private struct AnyLabelStyle: LabelStyle {
    private let makeBodyClosure: (Configuration) -> AnyView

    init<S: LabelStyle>(_ style: S) {
        makeBodyClosure = { AnyView(style.makeBody(configuration: $0)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        makeBodyClosure(configuration)
    }
}
#endif
