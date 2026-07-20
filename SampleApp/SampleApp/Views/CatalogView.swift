import SwiftUI

struct CatalogView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "checklist.checked")
                        .font(.largeTitle)
                        .foregroundStyle(.tint)
                    Text("Validated forms, exercised live")
                        .font(.title2.bold())
                        .accessibilityIdentifier(SampleAppAccessibility.catalogTitle)
                    Text("Each scenario is both an API showcase and a deterministic fixture for UI tests.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Scenarios") {
                ForEach(SampleScenario.allCases) { scenario in
                    NavigationLink {
                        ScenarioDestination(scenario: scenario)
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(scenario.title).font(.headline)
                                Text(scenario.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: scenario.systemImage)
                        }
                    }
                    .accessibilityIdentifier(SampleAppAccessibility.scenarioLink(scenario))
                }
            }

            Section("Coverage") {
                Label("Built-in and custom controls", systemImage: "switch.2")
                Label("Deep, optional, and list scopes", systemImage: "point.3.connected.trianglepath.dotted")
                Label("Manual, submit, and async validation", systemImage: "checkmark.seal")
                Label("Keyboard focus order", systemImage: "keyboard")
            }
        }
        .navigationTitle("Formulaire")
        .accessibilityIdentifier(SampleAppAccessibility.catalog)
    }
}

struct ScenarioDestination: View {
    let scenario: SampleScenario

    var body: some View {
        switch scenario {
        case .controls: ControlsFormView()
        case .nesting: NestedFormView()
        case .dynamicList: DynamicListFormView()
        }
    }
}

