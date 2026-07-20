import XCTest

nonisolated final class SampleUITests: XCTestCase {
    private var app: XCUIApplication!

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    @MainActor
    func testControlsValidationCustomFocusAndSubmission() {
        launch(.controls)
        XCTAssertTrue(app.scrollViews[A11y.controlsScreen].waitForExistence(timeout: 3))

        app.buttons[A11y.controlsValidate].tap()
        XCTAssertTrue(app.staticTexts[A11y.controlsStatus].label.contains("Invalid"))
        XCTAssertTrue(app.staticTexts[A11y.controlsEmailError].label.contains("valid email"))

        replaceText(in: app.textFields[A11y.controlsFullName], with: "Ada Lovelace")
        replaceText(in: app.textFields[A11y.controlsEmail], with: "ada@example.com")
        XCTAssertEqual(app.textFields[A11y.controlsFullName].value as? String, "Ada Lovelace")
        XCTAssertEqual(app.textFields[A11y.controlsEmail].value as? String, "ada@example.com")
        dismissKeyboard()

        app.buttons[A11y.controlsValidate].tap()
        XCTAssertEqual(app.staticTexts[A11y.controlsStatus].label, "Valid")
        app.buttons[A11y.controlsSubmit].tap()
        XCTAssertEqual(app.staticTexts[A11y.controlsStatus].label, "Submitted")

        app.buttons[A11y.controlsAsyncSubmit].tap()
        XCTAssertTrue(waitForLabel("Submitted asynchronously", on: app.staticTexts[A11y.controlsStatus]))

        app.textFields[A11y.controlsReferral].tap()
        app.textFields[A11y.controlsReferral].typeText("ABC")
        dismissKeyboard()
        app.buttons[A11y.controlsValidate].tap()
        XCTAssertTrue(app.staticTexts[A11y.controlsStatus].label.contains("Invalid"))
    }

    @MainActor
    func testKeyboardNavigationUsesRenderedFieldOrder() {
        launch(.controls)
        let name = app.textFields[A11y.controlsFullName]
        let email = app.textFields[A11y.controlsEmail]
        XCTAssertTrue(name.waitForExistence(timeout: 2))
        name.tap()

        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        XCTAssertTrue(email.hasKeyboardFocus)
        app.buttons["Done"].tap()
        XCTAssertFalse(email.hasKeyboardFocus)
    }

    @MainActor
    func testDeepNestingAndOptionalLifecycle() {
        launch(.nesting)
        XCTAssertTrue(app.descendants(matching: .any)[A11y.nestingScreen].waitForExistence(timeout: 3))

        app.buttons[A11y.nestingSubmit].tap()
        XCTAssertTrue(app.staticTexts[A11y.nestingErrorCount].label.contains("3 nested errors"))
        dismissKeyboard()

        app.buttons[A11y.nestingAddAlternate].tap()
        XCTAssertTrue(app.buttons[A11y.nestingRemoveAlternate].waitForExistence(timeout: 2))
        app.swipeUp()
        XCTAssertTrue(app.textFields[A11y.nestingAlternateCountry].waitForExistence(timeout: 2))

        let removeAlternate = app.buttons[A11y.nestingRemoveAlternate]
        XCTAssertTrue(scrollUntilHittable(removeAlternate, direction: .up))
        removeAlternate.tap()
        XCTAssertFalse(removeAlternate.waitForExistence(timeout: 2))
        XCTAssertTrue(scrollUntilExists(app.buttons[A11y.nestingAddAlternate], direction: .down))
    }

    @MainActor
    func testDynamicListValidationAndStableRows() {
        launch(.dynamicList)
        XCTAssertTrue(app.descendants(matching: .any)[A11y.listScreen].waitForExistence(timeout: 3))

        app.buttons[A11y.listSubmit].tap()
        XCTAssertTrue(app.staticTexts[A11y.listTopError].waitForExistence(timeout: 2))

        for _ in 0..<5 {
            let add = app.buttons[A11y.listAdd]
            XCTAssertTrue(scrollUntilExists(add, direction: .up))
            add.tap()
        }

        let firstName = app.textFields[A11y.listName("attendee-1")]
        XCTAssertTrue(scrollUntilExists(firstName, direction: .down))
        replaceText(in: firstName, with: "Ada")
        dismissKeyboard()
        XCTAssertTrue(scrollUntilExists(app.buttons[A11y.listSubmit], direction: .up))
        app.buttons[A11y.listSubmit].tap()
        XCTAssertTrue(waitForKeyboardFocus(on: app.textFields[A11y.listName("attendee-2")]))
        dismissKeyboard()

        let moveFirstDown = app.buttons[A11y.listMoveFirstDown]
        XCTAssertTrue(scrollUntilExists(moveFirstDown, direction: .up))
        moveFirstDown.tap()

        let removeFirst = app.buttons[A11y.listRemove("attendee-1")]
        XCTAssertTrue(scrollUntilExists(removeFirst, direction: .down))
        XCTAssertTrue(app.buttons[A11y.listRemove("attendee-2")].exists)
        removeFirst.tap()
        XCTAssertFalse(app.buttons[A11y.listRemove("attendee-1")].exists)
        XCTAssertTrue(app.buttons[A11y.listRemove("attendee-2")].exists)
    }

    @MainActor
    private func launch(_ scenario: Scenario) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "--scenario=\(scenario.rawValue)"]
        app.launch()
    }

    @MainActor
    private func replaceText(in field: XCUIElement, with text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.tap()
        if let current = field.value as? String, !current.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(text)
    }

    @MainActor
    private func dismissKeyboard() {
        let done = app.buttons["Done"]
        if done.waitForExistence(timeout: 2) {
            done.tap()
        }
    }

    @MainActor
    private func waitForLabel(_ label: String, on element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
        return XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 2) == .completed
    }

    @MainActor
    private func waitForKeyboardFocus(on element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "hasKeyboardFocus == true")
        return XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(predicate: predicate, object: element)],
            timeout: 2
        ) == .completed
    }

    @MainActor
    private func scrollUntilExists(
        _ element: XCUIElement,
        direction: SwipeDirection,
        attempts: Int = 8
    ) -> Bool {
        for _ in 0..<attempts {
            if element.exists { return true }
            switch direction {
            case .up: app.swipeUp()
            case .down: app.swipeDown()
            }
        }
        return element.exists
    }

    @MainActor
    private func scrollUntilHittable(
        _ element: XCUIElement,
        direction: SwipeDirection,
        attempts: Int = 8
    ) -> Bool {
        for _ in 0..<attempts {
            if element.isHittable { return true }
            switch direction {
            case .up: app.swipeUp()
            case .down: app.swipeDown()
            }
        }
        return element.isHittable
    }
}

private enum Scenario: String {
    case controls
    case nesting
    case dynamicList = "dynamic-list"
}

private enum SwipeDirection {
    case up
    case down
}

private enum A11y {
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
    static let nestingAlternateCountry = "sample.nesting.alternate-country"

    static let listScreen = "sample.list.screen"
    static let listAdd = "sample.list.add"
    static let listSubmit = "sample.list.submit"
    static let listMoveFirstDown = "sample.list.move-first-down"
    static let listTopError = "sample.list.top-error"
    static func listName(_ id: String) -> String { "sample.list.name.\(id)" }
    static func listRemove(_ id: String) -> String { "sample.list.remove.\(id)" }
}

private extension XCUIElement {
    var hasKeyboardFocus: Bool {
        (value(forKey: "hasKeyboardFocus") as? Bool) == true
    }
}
