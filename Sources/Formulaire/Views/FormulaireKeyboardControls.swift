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
    @FocusState.Binding var focus: FormulairePath?
    let renderedFields: [FormulairePath]
    let proxy: ScrollViewProxy
    let iconOnlyDoneButton: Bool

    var body: some View {
        HStack(spacing: iconOnlyDoneButton ? 24 : 12) {
            Button("Previous", systemImage: "chevron.up") {
                move(to: FormulaireFocusOrder.previous(in: renderedFields, current: focus))
            }
            .labelStyle(.iconOnly)
            .disabled(FormulaireFocusOrder.previous(in: renderedFields, current: focus) == nil)

            Button("Next", systemImage: "chevron.down") {
                move(to: FormulaireFocusOrder.next(in: renderedFields, current: focus))
            }
            .labelStyle(.iconOnly)
            .disabled(FormulaireFocusOrder.next(in: renderedFields, current: focus) == nil)

            Spacer(minLength: 0)

            Button("Done", systemImage: "checkmark") { focus = nil }
                .labelStyle(iconOnlyDoneButton ? AnyLabelStyle(.iconOnly) : AnyLabelStyle(.titleOnly))
                .bold()
        }
        .contentShape(Rectangle())
        .imageScale(.large)
        .fontWeight(.medium)
    }

    private func move(to destination: FormulairePath?) {
        guard let destination else { return }
        proxy.scrollTo(destination)
        DispatchQueue.main.async { focus = destination }
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

#Preview {
    PreviewView()
}

struct PreviewView: View {
    @State var text: String = ""
    @FocusState var isFocused: FormulairePath?

    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                TextField("Test", text: $text)
                    .focused($isFocused, equals: .root)
            }
            .formulaireKeyboardToolbar(focus: $isFocused, renderedFields: [], proxy: proxy)
        }
        .onAppear {
            isFocused = .root
        }
    }
}
