import Formulaire
import SwiftUI

struct ControlsFormView: View {
    @State private var model = ControlsFormModel()
    @State private var status = "Not validated"
    @State private var asyncSubmissionCount = 0

    var body: some View {
        FormulaireContent(editing: $model) { form in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    scenarioHeader

                    GroupBox("Convenience controls") {
                        VStack(alignment: .leading, spacing: 14) {
                            form.textField(
                                for: \.fullName,
                                prompt: Text("Ada Lovelace"),
                                accessibilityIdentifier: SampleAppAccessibility.controlsFullName
                            ) {
                                HStack {
                                    Image(systemName: "person").accessibilityHidden(true)
                                    Text("Full name")
                                }
                            }
                            Divider()
                            form.textField(
                                for: \.email,
                                label: "Email",
                                placeholder: "ada@example.com",
                                accessibilityIdentifier: SampleAppAccessibility.controlsEmail
                            )
                            Divider()
                            form.stepper(
                                for: \.age,
                                range: 0...120,
                                accessibilityIdentifier: SampleAppAccessibility.controlsAge
                            ) {
                                Text("Age")
                            }
                            Divider()
                            form.toggle(
                                for: \.receivesUpdates,
                                accessibilityLabel: Text("Receive product updates"),
                                accessibilityIdentifier: SampleAppAccessibility.controlsUpdates
                            ) {
                                HStack {
                                    Image(systemName: "envelope").accessibilityHidden(true)
                                    Text("Receive product updates")
                                }
                            }
                        }
                        .padding(.top, 8)
                    }

                    GroupBox("Custom controls") {
                        VStack(alignment: .leading, spacing: 14) {
                            form.control(for: \.startDate, focusable: false) { field in
                                DatePicker("Start date", selection: field.$value, displayedComponents: .date)
                            }

                            Divider()

                            form.control(for: \.referralCode, focusable: true) { field in
                                VStack(alignment: .leading, spacing: 6) {
                                    TextField("Referral code", text: field.$value)
                                        .textInputAutocapitalization(.characters)
                                        .focused(field.$focus, equals: field.id)
                                        .accessibilityIdentifier(SampleAppAccessibility.controlsReferral)
                                    if let error = field.error {
                                        Text(error.localizedDescription).font(.caption).foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }

                    GroupBox("Validation") {
                        VStack(alignment: .leading, spacing: 12) {
                            Button("Validate and focus email") {
                                let result = form.validation()
                                status = result.isValid ? "Valid" : "Invalid · \(result.errors.count) errors"
                                if form.error(for: \.email) != nil {
                                    _ = form.focus(on: \.email)
                                }
                            }
                            .accessibilityIdentifier(SampleAppAccessibility.controlsValidate)

                            form.submitButton("Submit") {
                                status = "Submitted"
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier(SampleAppAccessibility.controlsSubmit)

                            form.asyncSubmitButton(action: {
                                try? await Task.sleep(for: .seconds(1))
                                guard !Task.isCancelled else { return }
                                asyncSubmissionCount += 1
                                status = "Submitted asynchronously (\(asyncSubmissionCount))"
                            }) {
                                Label("Submit asynchronously", systemImage: "clock.arrow.circlepath")
                            }
                            .accessibilityIdentifier(SampleAppAccessibility.controlsAsyncSubmit)

                            Text(status)
                                .font(.callout.monospaced())
                                .accessibilityIdentifier(SampleAppAccessibility.controlsStatus)
                            Text(form.error(for: \.email)?.localizedDescription ?? "No email error")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier(SampleAppAccessibility.controlsEmailError)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
        }
        .formulaireStyle(FormulaireStyle(errorColor: .orange, focusedLabelColor: .purple))
        .navigationTitle("Controls")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(SampleAppAccessibility.controlsScreen)
    }

    private var scenarioHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Controls and focus").font(.title2.bold())
            Text("Exercises the custom-container API, every convenience control, custom focus, styling, and all submit paths.")
                .foregroundStyle(.secondary)
        }
    }
}
