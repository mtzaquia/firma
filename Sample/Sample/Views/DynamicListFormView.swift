import Formulaire
import SwiftUI

struct DynamicListFormView: View {
    @State private var model = EventFormModel()
    @State private var nextID = 1
    @State private var status = "Not validated"

    var body: some View {
        FormulaireView(editing: $model) { form in
            Section("Event") {
                form.textField(for: \.eventName, label: "Event name")
            }

            form.content(for: \.attendees) { error in
                Section {
                    ForEach(model.attendees) { attendee in
                        if let row = form.scope(\.attendees, id: attendee.id) {
                            Group {
                                row.textField(
                                    for: \.name,
                                    label: "Attendee name",
                                    accessibilityIdentifier: SampleAppAccessibility.listName(attendee.id)
                                )
                                row.stepper(for: \.ticketCount, label: "Tickets", range: 1...8)
                                row.toggle(for: \.needsAccessibilitySupport, label: "Accessibility support")
                                Button("Remove \(attendee.id)", role: .destructive) {
                                    model.attendees.remove(id: attendee.id)
                                }
                                .accessibilityIdentifier(SampleAppAccessibility.listRemove(attendee.id))
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
                            model.attendees.move(fromOffsets: IndexSet(integer: 0), toOffset: 2)
                        }
                        .accessibilityIdentifier(SampleAppAccessibility.listMoveFirstDown)
                    }
                } header: {
                    Text("Attendees")
                } footer: {
                    if let error {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier(SampleAppAccessibility.listTopError)
                    }
                }
            }

            Section {
                form.submitButton("Save event") { status = "Submitted" }
                    .accessibilityIdentifier(SampleAppAccessibility.listSubmit)
                Text(status)
                    .accessibilityIdentifier(SampleAppAccessibility.listStatus)
            }
        }
        .navigationTitle("Dynamic lists")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(SampleAppAccessibility.listScreen)
    }
}
