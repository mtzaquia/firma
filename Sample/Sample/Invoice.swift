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

import Formulaire
import Foundation
import SwiftUI

@Observable @Formulaire
final class Invoice: CustomStringConvertible {
    var number: Int = 1
    var date: Date = Date()
    var client: Client?
    var items: IdentifiedArrayOf<InvoiceItem> = []
    var notes: String = ""

    func validate() {
        if number < 1 {
            addError("Number must be greater than zero.", for: \.number)
        }

        if client == nil {
            addError("A client is required.", for: \.client)
        }

        validate(\.client)

        if items.isEmpty {
            addError("At least one item is required.", for: \.items)
        }

        validate(\.items)
    }

    var description: String {
        "Invoice"
        + "\n - \(number)"
        + "\n - \(date)"
        + "\n - \(String(describing: client))"
        + "\n - \(items)"
    }
}

@Observable @Formulaire
final class InvoiceItem: Identifiable {
    var id: String = UUID().uuidString

    var summary: String = ""
    var description: String = ""
    var amount: Decimal = .zero

    func validate() {
        if summary.isEmpty {
            addError("The summary must not be empty.", for: \.summary)
        }
    }
}

@Observable @Formulaire
final class Client: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String = ""

    func validate() {
        if name.isEmpty {
            addError("A name is required.", for: \.name)
        }
    }
}

func == (lhs: Client, rhs: Client) -> Bool {
    lhs.id == rhs.id
}

extension Hashable where Self: Identifiable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct InvoiceForm: View {
    @State var invoice = Invoice()

    let sampleClients: [Client] = [
        { let c1 = Client(); c1.name = "Sample 1"; return c1 }(),
        { let c2 = Client(); c2.name = "Sample 2"; return c2 }(),
        { let c3 = Client(); c3.name = "Sample 3"; return c3 }(),
    ]

    @State var hasErrors = false

    var body: some View {
        FormulaireView(editing: $invoice) { form in
            Section {
                form.stepper(for: \.number, label: "Invoice number")
                form.textField(for: \.notes, label: "Notes", placeholder: "Internal notes")
                form.control(for: \.date, focusable: false) { builder in
                    VStack {
                        DatePicker("Date", selection: builder.$value, displayedComponents: .date)

                        if let error = builder.error {
                            Text(error.localizedDescription)
                                .foregroundStyle(.red)
                        }
                    }
                }
                form.control(for: \.client, focusable: false) { builder in
                    VStack(alignment: .leading) {
                        Picker("Client", selection: builder.$value) {
                            if builder.value == nil {
                                Text("Pick...")
                                    .tag(nil as Client?)
                            }
                            ForEach(sampleClients) { client in
                                Text(client.name)
                                    .tag(client as Client?)
                            }
                        }

                        if let error = builder.error {
                            Text(error.localizedDescription)
                                .foregroundStyle(.red)
                        }
                    }

                    if builder.value != nil {
                        Button(
                            action: { builder.value = nil },
                            label: {
                                Label("Clear", systemImage: "xmark.circle")
                            }
                        )
                    }
                }

            }

            form.content(for: \.items) { error in
                Section {
                    ForEach(invoice.items) { item in
                        let scoped = form.scope(\.items, for: item)
                        scoped.textField(for: \.summary, label: "Summary")
                        scoped.textField(for: \.description, label: "Description")
                    }
                    .onDelete { offsets in
                        invoice.items.remove(atOffsets: offsets)
                    }

                    Button("Add") {
                        invoice.items.append(.init())
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
                LabeledContent("Has errors", value: invoice.__validator.errors.isEmpty ? "No" : "Yes")
                Text(invoice.__validator.errors.description)
                form.submitButton("Validate") {
                    print("Success!")
                }
            }
        }
    }
}
