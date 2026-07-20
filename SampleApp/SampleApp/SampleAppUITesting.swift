import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum SampleScenario: String, CaseIterable, Identifiable {
    case controls
    case nesting
    case dynamicList = "dynamic-list"

    var id: Self { self }

    var title: String {
        switch self {
        case .controls: "Controls and focus"
        case .nesting: "Nesting and optionals"
        case .dynamicList: "Dynamic identified lists"
        }
    }

    var subtitle: String {
        switch self {
        case .controls: "Built-in and custom controls, manual focus, styling, and submit APIs."
        case .nesting: "Deep scopes, parent errors, optional children, and nested validation summaries."
        case .dynamicList: "Stable identity, insertion, removal, reordering, and per-row validation."
        }
    }

    var systemImage: String {
        switch self {
        case .controls: "slider.horizontal.3"
        case .nesting: "square.stack.3d.up"
        case .dynamicList: "list.bullet.rectangle"
        }
    }
}

enum SampleAppUITesting {
    static let isEnabled = ProcessInfo.processInfo.arguments.contains("UI_TESTING")

    static let initialScenario: SampleScenario? = ProcessInfo.processInfo.arguments
        .first(where: { $0.hasPrefix("--scenario=") })
        .flatMap { SampleScenario(rawValue: String($0.dropFirst("--scenario=".count))) }

    static let initialAttendeeCount: Int = ProcessInfo.processInfo.arguments
        .first(where: { $0.hasPrefix("--attendees=") })
        .flatMap { Int($0.dropFirst("--attendees=".count)) }
        ?? 0

    @MainActor
    static func configure() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        UIView.setAnimationsEnabled(false)
        #endif
    }
}

enum SampleAppAccessibility {
    static let catalog = "sample.catalog"
    static let catalogTitle = "sample.catalog.title"
    static func scenarioLink(_ scenario: SampleScenario) -> String { "sample.catalog.\(scenario.rawValue)" }

    static let controlsScreen = "sample.controls.screen"
    static let controlsValidate = "sample.controls.validate"
    static let controlsSubmit = "sample.controls.submit"
    static let controlsAsyncSubmit = "sample.controls.async-submit"
    static let controlsFullName = "sample.controls.full-name"
    static let controlsEmail = "sample.controls.email"
    static let controlsAge = "sample.controls.age"
    static let controlsUpdates = "sample.controls.updates"
    static let controlsReferral = "sample.controls.referral"
    static let controlsStatus = "sample.controls.status"
    static let controlsEmailError = "sample.controls.email-error"

    static let nestingScreen = "sample.nesting.screen"
    static let nestingSubmit = "sample.nesting.submit"
    static let nestingAddAlternate = "sample.nesting.add-alternate"
    static let nestingRemoveAlternate = "sample.nesting.remove-alternate"
    static let nestingErrorCount = "sample.nesting.error-count"
    static let nestingStatus = "sample.nesting.status"
    static let nestingAlternateCountry = "sample.nesting.alternate-country"

    static let listScreen = "sample.list.screen"
    static let listAdd = "sample.list.add"
    static let listSubmit = "sample.list.submit"
    static let listMoveFirstDown = "sample.list.move-first-down"
    static let listTopError = "sample.list.top-error"
    static let listStatus = "sample.list.status"
    static func listName(_ id: String) -> String { "sample.list.name.\(id)" }
    static func listRemove(_ id: String) -> String { "sample.list.remove.\(id)" }
}
