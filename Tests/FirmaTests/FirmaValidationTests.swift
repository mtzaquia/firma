import Foundation
import IdentifiedCollections
import SwiftUI
import Testing
@testable import Firma

extension String: @retroactive LocalizedError {
    nonisolated public var errorDescription: String? { self }
}

@Observable @FormModel
final class TestCountry {
    var code: String = ""

    func validate(_ validation: ValidationContext<TestCountry>) {
        if code.isEmpty { validation.addError("Country code is required", for: \.code) }
    }
}

@Observable @FormModel
final class TestAddress {
    var street: String = ""
    var city: String = ""
    var country: TestCountry = TestCountry()

    func validate(_ validation: ValidationContext<TestAddress>) {
        if street.isEmpty { validation.addError("Street is required", for: \.street) }
        validation.validate(\.country)
    }
}

@Observable @FormModel
final class TestPhone: Identifiable {
    var id: String
    var label: String = ""

    init(id: String) { self.id = id }

    func validate(_ validation: ValidationContext<TestPhone>) {
        if label.isEmpty { validation.addError("Label is required", for: \.label) }
    }
}

@Observable @FormModel
final class TestPerson {
    var name: String = ""
    var address: TestAddress = TestAddress()
    var address2: TestAddress = TestAddress()
    var phones: IdentifiedArrayOf<TestPhone> = []
    var optionalAddress: TestAddress?

    func validate(_ validation: ValidationContext<TestPerson>) {
        if name.isEmpty { validation.addError("Name is required", for: \.name) }
        if phones.isEmpty { validation.addError("At least one phone is required", for: \.phones) }
        if optionalAddress == nil { validation.addError("An address is required", for: \.optionalAddress) }
        validation.validate(\.address)
        validation.validate(\.address2)
        validation.validate(\.phones)
        validation.validate(\.optionalAddress)
    }
}

private struct CollidingID: Hashable {
    let rawValue: Int
    func hash(into hasher: inout Hasher) { hasher.combine(0) }
}

@Observable @FormModel
private final class CollidingItem: Identifiable {
    var id: CollidingID
    var value: String = ""

    init(id: CollidingID) { self.id = id }
    func validate(_ validation: ValidationContext<CollidingItem>) {
        if value.isEmpty { validation.addError("Value is required", for: \.value) }
    }
}

@Observable @FormModel
private final class CollidingList {
    var items: IdentifiedArrayOf<CollidingItem> = []
    func validate(_ validation: ValidationContext<CollidingList>) {
        validation.validate(\.items)
    }
}

@Observable
private final class TestIDStore {
    var ids = ["first", "second"]
    var phones: IdentifiedArrayOf<TestPhone> = [
        TestPhone(id: "first"),
        TestPhone(id: "second"),
    ]
}

@Suite("Validation")
struct FirmaValidationTests {
    @Test("validate owns clearing and returns a snapshot")
    func validationLifecycle() {
        let person = validPerson()
        person.name = ""

        let invalid = person.validate()
        #expect(!invalid.isValid)
        #expect(invalid.errors[field("name")] != nil)

        person.name = "Taylor"
        let valid = person.validate()
        #expect(valid.isValid)
        #expect(person.__validator.errors.isEmpty)
    }

    @Test("deep paths retain every ancestor")
    func deepPaths() {
        let person = validPerson()
        person.address.country.code = ""
        person.address2.country.code = ""

        let result = person.validate()
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

        let result = model.validate()
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

        let result = person.validate()
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
        _ = person.validate()

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

        let result = person.validate()
        #expect(result.errors[field("address", "street")] != nil)
        #expect(result.errors[field("address2", "street")] != nil)
    }

    @Test("optional validation replaces top-level errors with nested errors")
    func optionalValidation() {
        let person = validPerson()
        person.optionalAddress = nil
        var result = person.validate()
        #expect(result.errors[field("optionalAddress")] != nil)

        let address = TestAddress()
        address.country.code = "NL"
        person.optionalAddress = address
        result = person.validate()
        #expect(result.errors[field("optionalAddress")] == nil)
        #expect(result.errors[field("optionalAddress", "street")] != nil)
    }

    @Test("field metadata reads and writes")
    func fieldMetadata() {
        let person = TestPerson()
        let metadata = TestPerson.__fields.name
        #expect(metadata.get(person) == "")
        metadata.set(person, "Morgan")
        #expect(person.name == "Morgan")
    }

    @Test("validation snapshots preserve only supplied, unique error paths")
    func validationResultOrdering() {
        let first = field("first")
        let second = field("second")
        let missing = field("missing")
        let result = ValidationResult(
            errors: [first: "First", second: "Second"],
            errorPaths: [second, second, missing, first]
        )

        #expect(result.errorPaths == [second, first])
    }
}

@Suite("Scoped bindings")
struct FirmaScopedBindingTests {
    @Test("a retained child binding cannot recreate a removed value")
    func removedOptionalRejectsStaleWrites() {
        var child: Int? = 1
        let binding = FirmaRetainedBinding.make(
            initialValue: 1,
            currentValue: { child },
            setIfPresent: { child = $0 }
        )

        child = nil
        binding.wrappedValue = 2

        #expect(child == nil)
        #expect(binding.wrappedValue == 1)
    }
}

@Suite("Focus order")
struct FirmaFocusOrderTests {
    @Test("identified element order observation survives reused views")
    func identifiedElementObservation() async {
        let store = TestIDStore()
        let observer = FirmaElementOrderObserver()
        var receivedIDs: [AnyHashable] = []
        observer.start(
            observing: FirmaElementOrder(
                listPath: field("items"),
                currentIDs: { store.ids.map { AnyHashable($0) } }
            )
        ) { snapshot in
            receivedIDs = snapshot.ids
        }

        store.ids = ["second", "first"]
        for _ in 0..<10 where receivedIDs != store.ids.map({ AnyHashable($0) }) {
            await Task.yield()
        }

        #expect(receivedIDs == store.ids.map { AnyHashable($0) })
        observer.stop()

        let collectionObserver = FirmaElementOrderObserver()
        collectionObserver.start(
            observing: FirmaElementOrder(
                listPath: field("phones"),
                currentIDs: { store.phones.map { AnyHashable($0.id) } }
            )
        ) { snapshot in
            receivedIDs = snapshot.ids
        }

        store.phones.move(fromOffsets: IndexSet(integer: 0), toOffset: 2)
        let expected = [AnyHashable("second"), AnyHashable("first")]
        for _ in 0..<10 where receivedIDs != expected {
            await Task.yield()
        }

        #expect(receivedIDs == expected)
        collectionObserver.stop()
    }

    @Test("next and previous follow rendered order")
    func focusOrder() {
        let fields = [field("name"), field("email"), field("address", "street")]

        #expect(
            FirmaFocusOrder.candidates(
                in: fields,
                current: fields[0],
                direction: .next
            ) == [fields[1], fields[2]]
        )
        #expect(
            FirmaFocusOrder.candidates(
                in: fields,
                current: fields[2],
                direction: .previous
            ) == [fields[1], fields[0]]
        )
        #expect(
            FirmaFocusOrder.candidates(
                in: fields,
                current: fields[2],
                direction: .next
            ).isEmpty
        )
        #expect(
            FirmaFocusOrder.candidates(
                in: fields,
                current: field("missing"),
                direction: .next
            ).isEmpty
        )
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
        #expect(
            FirmaFocusOrder.candidates(in: before, current: before[0], direction: .next).first
                == firstPath
        )
        #expect(
            FirmaFocusOrder.candidates(in: after, current: after[0], direction: .next).first
                == secondPath
        )
    }

    @Test("lazy snapshots preserve and extend logical order")
    func lazySnapshots() {
        let event = field("event")
        let first = field("attendees", "first")
        let second = field("attendees", "second")
        let third = field("attendees", "third")
        let fourth = field("attendees", "fourth")

        var order = FirmaFocusOrder.reconciling(
            [event, first, second],
            with: []
        )
        order = FirmaFocusOrder.reconciling(
            [second, third, fourth],
            with: order
        )

        #expect(order == [event, first, second, third, fourth])
        #expect(
            FirmaFocusOrder.candidates(in: order, current: third, direction: .next).first
                == fourth
        )
        #expect(
            FirmaFocusOrder.candidates(in: order, current: third, direction: .previous).first
                == second
        )
    }

    @Test("visible reordering updates known fields in place")
    func visibleReordering() {
        let event = field("event")
        let first = field("attendees", "first")
        let second = field("attendees", "second")
        let third = field("attendees", "third")
        let submit = field("submit")

        let order = FirmaFocusOrder.reconciling(
            [second, first, third],
            with: [event, first, second, third, submit]
        )

        #expect(order == [event, second, first, third, submit])
    }

    @Test("identified element order follows model reordering and deletion")
    func identifiedElementOrder() {
        let event = field("event")
        let attendees = field("attendees")
        let first = attendees.appending(elementID: "first").appending(field: "name")
        let second = attendees.appending(elementID: "second").appending(field: "name")
        let third = attendees.appending(elementID: "third").appending(field: "name")
        let submit = field("submit")

        var order = FirmaFocusOrder.reconcilingElements(
            in: [event, first, second, third, submit],
            under: attendees,
            ids: ["second", "first", "third"].map(AnyHashable.init)
        )
        #expect(order == [event, second, first, third, submit])

        order = FirmaFocusOrder.reconcilingElements(
            in: order,
            under: attendees,
            ids: ["second", "third"].map(AnyHashable.init)
        )
        #expect(order == [event, second, third, submit])
    }

    @Test("field order follows visual position, not preference reduction order")
    func visualFieldOrder() {
        let first = field("first")
        let second = field("second")
        let third = field("third")
        let entries = [
            FirmaFieldOrderEntry(path: third, frame: CGRect(x: 0, y: 300, width: 100, height: 40)),
            FirmaFieldOrderEntry(path: first, frame: CGRect(x: 0, y: 100, width: 100, height: 40)),
            FirmaFieldOrderEntry(path: second, frame: CGRect(x: 0, y: 200, width: 100, height: 40)),
        ]

        #expect(FirmaFieldOrderPreferenceKey.orderedPaths(from: entries) == [first, second, third])
    }

    @Test("missing fields between visible anchors are pruned")
    func removedFields() {
        let event = field("event")
        let removed = field("attendees", "removed")
        let second = field("attendees", "second")
        let third = field("attendees", "third")
        let offscreen = field("attendees", "offscreen")

        let order = FirmaFocusOrder.reconciling(
            [event, second, third],
            with: [event, removed, second, third, offscreen]
        )

        #expect(order == [event, second, third, offscreen])
    }
}

private func field(_ components: String...) -> FirmaPath {
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
