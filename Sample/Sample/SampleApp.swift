import SwiftUI

extension String: @retroactive LocalizedError {
    nonisolated public var errorDescription: String? { self }
}
@main
struct FormulaireSampleApp: App {
    init() {
        SampleAppUITesting.configure()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if let scenario = SampleAppUITesting.initialScenario {
                    ScenarioDestination(scenario: scenario)
                } else {
                    CatalogView()
                }
            }
            .transaction { transaction in
                if SampleAppUITesting.isEnabled {
                    transaction.animation = nil
                }
            }
        }
    }
}
