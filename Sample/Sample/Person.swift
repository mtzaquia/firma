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

import Foundation
import Formulaire
import SwiftUI

@Observable @Formulaire
final class Person {
    var name: String = ""
    var address: Address = Address()
    var optionalAddress: Address?
    var phones: IdentifiedArrayOf<Phone> = []

    var computedProperty: String { "Can't be used because it's computed" }
    let readOnlyProperty: String = "Can't be used because it's `let`"

    func validate() {
        if name.isEmpty {
            addError("Name is required", for: \.name)
        }

        validate(\.address)

        if phones.isEmpty {
            addError("At least one phone is required", for: \.phones)
        }

        validate(\.phones)

        if optionalAddress == nil {
            addError("An alternate address is required", for: \.optionalAddress)
        }

        validate(\.optionalAddress)
    }
}

@Observable @Formulaire
final class Phone: Identifiable {
    var id: String = UUID().uuidString
    var label: String = ""
    var number: String = ""

    func validate() {
        if label.isEmpty {
            addError("Label is required", for: \.label)
        }

        if number.isEmpty {
            addError("Phone number is required", for: \.number)
        }
    }
}

@Observable @Formulaire
final class Address {
    var addressLine1: String = ""
    var addressLine2: String = ""
    var city: String = ""
    var zipCode: String = ""

    func validate() {
        if addressLine1.isEmpty {
            addError("Address line 1 is required", for: \.addressLine1)
        }

        if city.isEmpty {
            addError("City is required", for: \.city)
        }

        if zipCode.isEmpty {
            addError("ZIP code is required", for: \.zipCode)
        }
    }
}

struct PersonForm: View {
    @State private var person = Person()

    @State private var success = false

    var body: some View {
        FormulaireView(editing: $person) { form in
            Section {
                form.textField(for: \.name, label: "Name")
            }

            Section {
                let scoped = form.scope(\.address)
                scoped.textField(for: \.addressLine1, label: "Address line 1")
                scoped.textField(for: \.addressLine2, label: "Address line 2")
                scoped.textField(for: \.zipCode, label: "ZIP code")
                scoped.textField(for: \.city, label: "City")
            }

            Section {
                if person.optionalAddress == nil {
                    Button("Add alternate address") {
                        person.optionalAddress = Address()
                    }
                } else if let scoped = form.scope(\.optionalAddress) {
                    scoped.textField(for: \.addressLine1, label: "Alt address line 1")
                    scoped.textField(for: \.addressLine2, label: "Alt address line 2")
                    scoped.textField(for: \.zipCode, label: "Alt ZIP code")
                    scoped.textField(for: \.city, label: "Alt city")

                    Button("Remove alternate address") {
                        person.optionalAddress = nil
                    }
                    .foregroundStyle(.red)
                }
            } header: {
                Text("Alternate Address")
            }

            form.content(for: \.phones) { error in
                Section {
                    ForEach(person.phones) { phone in
                        let scoped = form.scope(\.phones, for: phone)
                        scoped.textField(for: \.label, label: "Label")
                        scoped.textField(for: \.number, label: "Number")
                    }
                    .onDelete { offsets in
                        person.phones.remove(atOffsets: offsets)
                    }

                    Button("Add phone") {
                        person.phones.append(Phone())
                    }
                } footer: {
                    if let error {
                        Text(error.localizedDescription)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                    }
                }
            }

            Section {
                LabeledContent("Has errors", value: person.__validator.errors.isEmpty ? "No" : "Yes")
                Text(person.__validator.errors.description)

                Button("Validate") {
                    success = form.validate()

                    if !success {
                        // Example of focusing on nested fields using a scoped form.
                        let scoped = form.scope(\.address)
                        scoped.focus(on: \.addressLine1)
                    }
                }
            }
        }
        .animation(.snappy, value: person.optionalAddress == nil)
        .alert("Success!", isPresented: $success) {
            Button("Ok") { success = false }
        }
    }
}
