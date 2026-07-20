import Foundation
import IdentifiedCollections
import SwiftUI
import Testing
@testable import Formulaire

extension String: @retroactive LocalizedError {
    nonisolated public var errorDescription: String? { self }
}

@Observable @Formulaire
final class TestCountry {
    var code: String = ""

    func validate() {
        if code.isEmpty { addError("Country code is required", for: \.code) }
    }
}

@Observable @Formulaire
final class TestAddress {
    var street: String = ""
    var city: String = ""
    var country: TestCountry = TestCountry()

    func validate() {
        if street.isEmpty { addError("Street is required", for: \.street) }
        validate(\.country)
    }
}

@Observable @Formulaire
final class TestPhone: Identifiable {
    var id: String
    var label: String = ""

    init(id: String) { self.id = id }

    func validate() {
        if label.isEmpty { addError("Label is required", for: \.label) }
    }
}

@Observable @Formulaire
final class TestPerson {
    var name: String = ""
    var address: TestAddress = TestAddress()
    var address2: TestAddress = TestAddress()
    var phones: IdentifiedArrayOf<TestPhone> = []
    var optionalAddress: TestAddress?

    func validate() {
        if name.isEmpty { addError("Name is required", for: \.name) }
        if phones.isEmpty { addError("At least one phone is required", for: \.phones) }
        if optionalAddress == nil { addError("An address is required", for: \.optionalAddress) }
        validate(\.address)
        validate(\.address2)
        validate(\.phones)
        validate(\.optionalAddress)
    }
}

private struct CollidingID: Hashable {
    let rawValue: Int
    func hash(into hasher: inout Hasher) { hasher.combine(0) }
}

@Observable @Formulaire
private final class CollidingItem: Identifiable {
    var id: CollidingID
    var value: String = ""

    init(id: CollidingID) { self.id = id }
    func validate() {
        if value.isEmpty { addError("Value is required", for: \.value) }
    }
}

@Observable @Formulaire
private final class CollidingList {
    var items: IdentifiedArrayOf<CollidingItem> = []
    func validate() { validate(\.items) }
}

@Suite("Validation")
struct FormulaireValidationTests {
    @Test("runValidation owns clearing and returns a snapshot")
    func validationLifecycle() {
        let person = validPerson()
        person.name = ""

        let invalid = person.runValidation()
        #expect(!invalid.isValid)
        #expect(invalid.errors[field("name")] != nil)

        person.name = "Taylor"
        let valid = person.runValidation()
        #expect(valid.isValid)
        #expect(person.__validator.errors.isEmpty)
    }

    @Test("deep paths retain every ancestor")
    func deepPaths() {
        let person = validPerson()
        person.address.country.code = ""
        person.address2.country.code = ""

        let result = person.runValidation()
        #expect(result.errors[field("address", "country", "code")] != nil)
        #expect(result.errors[field("address2", "country", "code")] != nil)
        #expect(result.errors.count == 2)
    }

    @Test("identified list paths retain actual IDs, even when hashes collide")
    func collidingListIDs() {
        let first = CollidingItem(id: CollidingID(rawValue: 1))
        let second = CollidingItem(id: CollidingID(rawValue: 2))
        let model = CollidingList()
        model.items = [first, second]

        let result = model.runValidation()
        let listPath = field("items")
        let firstPath = listPath.appending(elementID: first.id).appending(field: "value")
        let secondPath = listPath.appending(elementID: second.id).appending(field: "value")

        #expect(first.id.hashValue == second.id.hashValue)
        #expect(firstPath != secondPath)
        #expect(result.errors[firstPath] != nil)
        #expect(result.errors[secondPath] != nil)
    }

    @Test("identified list errors retain model order")
    func identifiedListErrorOrder() {
        let person = validPerson()
        person.phones = IdentifiedArray(uniqueElements: (1...5).map { index in
            let phone = TestPhone(id: "phone-\(index)")
            if index == 1 { phone.label = "Primary" }
            return phone
        })

        let result = person.runValidation()
        let phones = field("phones")
        let expected = (2...5).map {
            phones.appending(elementID: "phone-\($0)").appending(field: "label")
        }

        #expect(result.errorPaths == expected)
    }

    @Test("validating one prefix preserves a similarly named sibling")
    func prefixBoundaries() {
        let person = validPerson()
        person.address.street = ""
        person.address2.street = ""
        _ = person.runValidation()

        person.address.street = "Main"
        _ = person.__validator.replaceValidation(of: person.address, at: field("address"))

        #expect(person.__validator.errors[field("address", "street")] == nil)
        #expect(person.__validator.errors[field("address2", "street")] != nil)
    }

    @Test("the same nested object can be validated at two paths")
    func reusedNestedObject() {
        let shared = TestAddress()
        shared.street = ""
        shared.country.code = "NL"

        let person = validPerson()
        person.address = shared
        person.address2 = shared

        let result = person.runValidation()
        #expect(result.errors[field("address", "street")] != nil)
        #expect(result.errors[field("address2", "street")] != nil)
    }

    @Test("optional validation replaces top-level errors with nested errors")
    func optionalValidation() {
        let person = validPerson()
        person.optionalAddress = nil
        var result = person.runValidation()
        #expect(result.errors[field("optionalAddress")] != nil)

        let address = TestAddress()
        address.country.code = "NL"
        person.optionalAddress = address
        result = person.runValidation()
        #expect(result.errors[field("optionalAddress")] == nil)
        #expect(result.errors[field("optionalAddress", "street")] != nil)
    }

    @Test("field metadata reads and writes")
    func fieldMetadata() {
        var person = TestPerson()
        let metadata = TestPerson.__fields.name
        #expect(person[field: metadata] == "")
        person[field: metadata] = "Morgan"
        #expect(person.name == "Morgan")
    }
}

@Suite("Focus order")
struct FormulaireFocusOrderTests {
    @Test("next and previous follow rendered order")
    func focusOrder() {
        let fields = [field("name"), field("email"), field("address", "street")]

        #expect(FormulaireFocusOrder.next(in: fields, current: fields[0]) == fields[1])
        #expect(FormulaireFocusOrder.next(in: fields, current: fields[2]) == nil)
        #expect(FormulaireFocusOrder.previous(in: fields, current: fields[2]) == fields[1])
        #expect(FormulaireFocusOrder.previous(in: fields, current: fields[0]) == nil)
        #expect(FormulaireFocusOrder.next(in: fields, current: field("missing")) == nil)
    }

    @Test("actual list identity survives reordering")
    func listReordering() {
        let first = TestPhone(id: "first")
        let second = TestPhone(id: "second")
        let root = field("phones")
        let firstPath = root.appending(elementID: first.id).appending(field: "label")
        let secondPath = root.appending(elementID: second.id).appending(field: "label")
        let before = [field("name"), firstPath, secondPath]
        let after = [field("name"), secondPath, firstPath]
        #expect(FormulaireFocusOrder.next(in: before, current: before[0]) == firstPath)
        #expect(FormulaireFocusOrder.next(in: after, current: after[0]) == secondPath)
    }

    @Test("lazy snapshots preserve and extend logical order")
    func lazySnapshots() {
        let event = field("event")
        let first = field("attendees", "first")
        let second = field("attendees", "second")
        let third = field("attendees", "third")
        let fourth = field("attendees", "fourth")

        var order = FormulaireFocusOrder.reconciling(
            [event, first, second],
            with: []
        )
        order = FormulaireFocusOrder.reconciling(
            [second, third, fourth],
            with: order
        )

        #expect(order == [event, first, second, third, fourth])
        #expect(FormulaireFocusOrder.next(in: order, current: third) == fourth)
        #expect(FormulaireFocusOrder.previous(in: order, current: third) == second)
    }

    @Test("visible reordering updates known fields in place")
    func visibleReordering() {
        let event = field("event")
        let first = field("attendees", "first")
        let second = field("attendees", "second")
        let third = field("attendees", "third")
        let submit = field("submit")

        let order = FormulaireFocusOrder.reconciling(
            [second, first, third],
            with: [event, first, second, third, submit]
        )

        #expect(order == [event, second, first, third, submit])
    }

    @Test("field order follows visual position, not preference reduction order")
    func visualFieldOrder() {
        let first = field("first")
        let second = field("second")
        let third = field("third")
        let entries = [
            FormulaireFieldOrderEntry(path: third, frame: CGRect(x: 0, y: 300, width: 100, height: 40)),
            FormulaireFieldOrderEntry(path: first, frame: CGRect(x: 0, y: 100, width: 100, height: 40)),
            FormulaireFieldOrderEntry(path: second, frame: CGRect(x: 0, y: 200, width: 100, height: 40)),
        ]

        #expect(FormulaireFieldOrderPreferenceKey.orderedPaths(from: entries) == [first, second, third])
    }

    @Test("missing fields between visible anchors are pruned")
    func removedFields() {
        let event = field("event")
        let removed = field("attendees", "removed")
        let second = field("attendees", "second")
        let third = field("attendees", "third")
        let offscreen = field("attendees", "offscreen")

        let order = FormulaireFocusOrder.reconciling(
            [event, second, third],
            with: [event, removed, second, third, offscreen]
        )

        #expect(order == [event, second, third, offscreen])
    }
}

private func field(_ components: String...) -> FormulairePath {
    components.reduce(.root) { $0.appending(field: $1) }
}

private func validPerson() -> TestPerson {
    let person = TestPerson()
    person.name = "Taylor"
    person.address.street = "Main"
    person.address.country.code = "NL"
    person.address2.street = "Second"
    person.address2.country.code = "NL"
    let phone = TestPhone(id: "primary")
    phone.label = "Mobile"
    person.phones = [phone]
    let optional = TestAddress()
    optional.street = "Optional"
    optional.country.code = "NL"
    person.optionalAddress = optional
    return person
}
