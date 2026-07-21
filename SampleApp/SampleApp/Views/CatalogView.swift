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
        .navigationTitle("Firma")
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

