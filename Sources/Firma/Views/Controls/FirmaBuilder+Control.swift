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
    /// Builds a custom control for a field.
    ///
    /// Pass `focusable: true` when `content` contains a single focus destination.
    /// Firma binds that content to its shared focus state and includes it in
    /// visual focus order automatically.
    ///
    /// - Parameters:
    ///   - field: The field represented by the custom control.
    ///   - focusable: Whether Firma should manage focus for the returned content.
    ///   - content: A view builder that receives the field binding and current state.
    func control<V, Content: View>(
        for field: FieldPath<F, V>,
        focusable: Bool,
        @ViewBuilder content: (ControlBuilder<V>) -> Content
    ) -> some View {
        let fieldPath = resolve(field).path
        let builder = ControlBuilder(
            id: fieldPath,
            value: binding(for: field),
            focus: focusCoordinator.focus,
            error: validator.errors[fieldPath]
        )

        return Group {
            if focusable {
                content(builder)
                    .focused(focusCoordinator.focus, equals: fieldPath)
            } else {
                content(builder)
            }
        }
        .id(fieldPath)
        .background {
            if focusable {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: FirmaFieldOrderPreferenceKey.self,
                        value: [
                            FirmaFieldOrderEntry(
                                path: fieldPath,
                                frame: proxy.frame(in: .global)
                            )
                        ]
                    )
                }
            }
        }
    }

    internal func controlWithInternalFocus<V, Content: View>(
        for field: FieldPath<F, V>,
        @ViewBuilder content: (ControlBuilder<V>) -> Content
    ) -> some View {
        let fieldPath = resolve(field).path

        return content(
            ControlBuilder(
                id: fieldPath,
                value: binding(for: field),
                focus: focusCoordinator.focus,
                error: validator.errors[fieldPath]
            )
        )
        .id(fieldPath)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: FirmaFieldOrderPreferenceKey.self,
                    value: [
                        FirmaFieldOrderEntry(
                            path: fieldPath,
                            frame: proxy.frame(in: .global)
                        )
                    ]
                )
            }
        }
    }
}
