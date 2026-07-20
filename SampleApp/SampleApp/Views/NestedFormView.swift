import Formulaire
import SwiftUI

struct NestedFormView: View {
    @State private var model = AccountFormModel()
    @State private var status = "Not validated"

    var body: some View {
        FormulaireContent(editing: $model) { form in
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
