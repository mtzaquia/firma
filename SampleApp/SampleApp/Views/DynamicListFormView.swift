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

struct DynamicListFormView: View {
    @State private var model: EventFormModel
    @State private var nextID: Int
    @State private var status = "Not validated"

    init() {
        let count = SampleAppUITesting.initialAttendeeCount
        let model = EventFormModel()
        let attendees = count > 0
            ? (1...count).map { AttendeeFormModel(id: "attendee-\($0)") }
            : []
        model.attendees = IdentifiedArray(
            uniqueElements: attendees
        )
        _model = State(initialValue: model)
        _nextID = State(initialValue: count + 1)
    }

    var body: some View {
        FirmaContent(editing: $model) { form in
            Form {
                Section("Event") {
                    form.textField(for: \.eventName, label: "Event name")
                }

                let attendeeError = form.error(for: \.attendees)
                Section {
                    ForEach(model.attendees) { attendee in
                        if let row = form.scope(\.attendees, id: attendee.id) {
                            Group {
                                row.textField(
                                    for: \.name,
                                    label: "Attendee name",
                                    accessibilityIdentifier: SampleAppAccessibility.listName(attendee.id)
                                )
                                Button("Remove \(attendee.id)", role: .destructive) {
                                    model.attendees.remove(id: attendee.id)
                                }
                                .accessibilityIdentifier(SampleAppAccessibility.listRemove(attendee.id))
                                row.stepper(for: \.ticketCount, label: "Tickets", range: 1...8)
                                row.toggle(for: \.needsAccessibilitySupport, label: "Accessibility support")
                            }
                        }
                    }

                    Button("Add attendee") {
                        model.attendees.append(AttendeeFormModel(id: "attendee-\(nextID)"))
                        nextID += 1
                    }
                    .accessibilityIdentifier(SampleAppAccessibility.listAdd)

                    if model.attendees.count > 1 {
                        Button("Move first attendee down") {
                            var attendees = model.attendees
                            attendees.move(fromOffsets: IndexSet(integer: 0), toOffset: 2)
                            model.attendees = attendees
                        }
                        .accessibilityIdentifier(SampleAppAccessibility.listMoveFirstDown)
                    }

                } header: {
                    Text("Attendees")
                } footer: {
                    if let attendeeError {
                        Text(attendeeError.localizedDescription)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier(SampleAppAccessibility.listTopError)
                    }
                }

                Section {
                    form.submitButton("Save event") { status = "Submitted" }
                        .accessibilityIdentifier(SampleAppAccessibility.listSubmit)
                    Text(status)
                        .accessibilityIdentifier(SampleAppAccessibility.listStatus)
                }
            }
        }
        .navigationTitle("Dynamic lists")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(SampleAppAccessibility.listScreen)
        .accessibilityValue(model.attendees.map(\.id).joined(separator: ","))
    }
}
