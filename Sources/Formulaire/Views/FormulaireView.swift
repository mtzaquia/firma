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

public struct FormulaireView<F: Formulaire, C: View>: View {
    @Binding private var subject: F
    @FocusState private var focus: String?

    private let builder: (FormulaireBuilder<F>) -> C
    private let renderedFields: Wrapper<[String]> = .init(value: [])

    public var body: some View {
        ScrollViewReader { proxy in
            let _ = renderedFields.value.removeAll()
            Form {
                builder(
                    FormulaireBuilder<F>(
                        formulaire: $subject,
                        scrollProxy: proxy,
                        focus: $focus,
                        renderedFields: renderedFields,
                        parent: nil,
                        validateFunction: {
                            subject.validate()
                        }
                    )
                )
            }
#if os(iOS)
            .modify { base in
                let info = Bundle.main.infoDictionary
                if #available(iOS 26, *), (info?["UIDesignRequiresCompatibility"] as? Bool) != true {
                    base
                        .safeAreaBar(edge: .bottom) {
                            if focus != nil {
                                HStack {
                                    previousButton(proxy: proxy)
                                        .frame(width: 34, height: 40)
                                    nextButton(proxy: proxy)
                                        .frame(width: 34, height: 40)
                                    Spacer(minLength: .zero)
                                    doneButton(.iconOnly)
                                        .frame(width: 34, height: 40)
                                }
                                .font(.title2)
                                .padding(.horizontal, 4)
                                .frame(height: 48)
                                .glassEffect(.clear.interactive())
                                .padding([.horizontal, .bottom])
                                .tint(.primary)
                                .transition(.blurReplace)
                            }
                        }
                } else {
                    base
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                HStack {
                                    previousButton(proxy: proxy)
                                    nextButton(proxy: proxy)
                                    Color.clear.frame(maxWidth: .infinity)
                                    doneButton(.titleOnly)
                                        .bold()
                                }
                            }
                        }
                }
            }
#endif
        }
    }

    public init(
        editing subject: Binding<F>,
        @ViewBuilder builder: @escaping (FormulaireBuilder<F>) -> C
    ) {
        self._subject = subject
        self.builder = builder
    }
}

private extension FormulaireView {
    private func previousButton(proxy: ScrollViewProxy) -> some View {
        Button(
            action: {
                let fields = renderedFields.value
                guard let currentIndex = focus.flatMap({ fields.firstIndex(of: $0) })
                else { return }

                if currentIndex - 1 >= 0 {
                    let previous = fields[currentIndex - 1]
                    proxy.scrollTo(previous)
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        focus = previous
                    }
                }
            },
            label: {
                Label(LocalizedStringResource(stringLiteral: "Previous"), systemImage: "chevron.up")
                    .labelStyle(.iconOnly)
                    .contentShape(Rectangle())
            }
        )
        .disabled(focus == renderedFields.value.first)
    }

    private func nextButton(proxy: ScrollViewProxy) -> some View {
        Button(
            action: {
                let fields = renderedFields.value
                guard let currentIndex = focus.flatMap({ fields.firstIndex(of: $0) })
                else { return }

                if currentIndex + 1 < fields.count {
                    let next = fields[currentIndex + 1]
                    proxy.scrollTo(next)
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        focus = next
                    }
                }
            },
            label: {
                Label(LocalizedStringResource(stringLiteral: "Next"), systemImage: "chevron.down")
                    .labelStyle(.iconOnly)
                    .contentShape(Rectangle())
            }
        )
        .disabled(focus == renderedFields.value.last)
    }

    @ViewBuilder
    private func doneButton(_ labelStyle: some LabelStyle) -> some View {
        Button(
            action: {
                focus = nil
            },
            label: {
                Label(LocalizedStringResource(stringLiteral: "Done"), systemImage: "checkmark")
                    .labelStyle(labelStyle)
                    .contentShape(Rectangle())
            }
        )
    }
}
