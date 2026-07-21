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
