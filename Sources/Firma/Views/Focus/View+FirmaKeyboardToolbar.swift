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

extension View {
    @ViewBuilder
    func firmaKeyboardToolbar(_ focusCoordinator: FirmaFocusCoordinator) -> some View {
        #if os(iOS)
        let isVisible = focusCoordinator.focus.wrappedValue != nil
        let info = Bundle.main.infoDictionary
        if #available(iOS 26, *), (info?["UIDesignRequiresCompatibility"] as? Bool) != true {
            safeAreaInset(edge: .bottom, spacing: 0) {
                Group {
                    if isVisible {
                        FirmaKeyboardControls(
                            focusCoordinator: focusCoordinator,
                            iconOnlyDoneButton: true
                        )
                        .padding()
                        .glassEffect(.regular, in: .capsule)
                        .transition(.blurReplace)
                        .padding([.horizontal, .bottom])
                    }
                }
                .allowsHitTesting(isVisible)
                .animation(.snappy, value: isVisible)
            }
        } else {
            toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    FirmaKeyboardControls(
                        focusCoordinator: focusCoordinator,
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
