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

import Firma
import SwiftUI

struct NestedFormView: View {
    @State private var model = AccountFormModel()
    @State private var status = "Not validated"

    var body: some View {
        FirmaContent(editing: $model) { form in
            Form {
                Section("Account") {
                    form.textField(for: \.username, label: "Username")
                }

                let primaryAddressErrors = form.errors(for: \.primaryAddress)
                Section {
                    let address = form.scope(\.primaryAddress)
                    address.textField(for: \.street, label: "Primary street")
                    address.textField(for: \.city, label: "Primary city")
                    let country = address.scope(\.country)
                    country.textField(for: \.code, label: "Primary country code")
                } header: {
                    Text("Primary address")
                } footer: {
                    Text("\(primaryAddressErrors.count) nested errors")
                        .accessibilityIdentifier(SampleAppAccessibility.nestingErrorCount)
                }

                Section("Alternate address") {
                    if let alternate = form.scope(\.alternateAddress) {
                        alternate.textField(for: \.street, label: "Alternate street")
                        alternate.textField(for: \.city, label: "Alternate city")
                        let country = alternate.scope(\.country)
                        country.textField(
                            for: \.code,
                            label: "Alternate country code",
                            accessibilityIdentifier: SampleAppAccessibility.nestingAlternateCountry
                        )

                        Button("Remove alternate address", role: .destructive) {
                            form.binding(for: \.alternateAddress).wrappedValue = nil
                        }
                        .accessibilityIdentifier(SampleAppAccessibility.nestingRemoveAlternate)
                    } else {
                        Button("Add alternate address") {
                            form.binding(for: \.alternateAddress).wrappedValue = AddressFormModel()
                        }
                        .accessibilityIdentifier(SampleAppAccessibility.nestingAddAlternate)
                    }

                    if let error = form.error(for: \.alternateAddress) {
                        Text(error.localizedDescription).font(.caption).foregroundStyle(.red)
                    }
                }

                Section {
                    form.submitButton("Create account") { status = "Submitted" }
                        .accessibilityIdentifier(SampleAppAccessibility.nestingSubmit)
                    Text(status)
                        .accessibilityIdentifier(SampleAppAccessibility.nestingStatus)
                }
            }
        }
        .navigationTitle("Nesting")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(SampleAppAccessibility.nestingScreen)
    }
}
