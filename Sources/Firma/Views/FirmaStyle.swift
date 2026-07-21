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

/// Visual configuration used by Firma's convenience controls.
public struct FirmaStyle {
    public var errorColor: Color
    public var focusedLabelColor: Color
    public var labelColor: Color
    public var uppercasesTextFieldLabels: Bool

    public init(
        errorColor: Color = .red,
        focusedLabelColor: Color = .accentColor,
        labelColor: Color = .secondary,
        uppercasesTextFieldLabels: Bool = true
    ) {
        self.errorColor = errorColor
        self.focusedLabelColor = focusedLabelColor
        self.labelColor = labelColor
        self.uppercasesTextFieldLabels = uppercasesTextFieldLabels
    }

    public static let `default` = FirmaStyle()
}

private struct FirmaStyleKey: EnvironmentKey {
    static let defaultValue = FirmaStyle.default
}

extension EnvironmentValues {
    var firmaStyle: FirmaStyle {
        get { self[FirmaStyleKey.self] }
        set { self[FirmaStyleKey.self] = newValue }
    }
}

public extension View {
    /// Overrides the appearance of Firma convenience controls in this subtree.
    func firmaStyle(_ style: FirmaStyle) -> some View {
        environment(\.firmaStyle, style)
    }
}

