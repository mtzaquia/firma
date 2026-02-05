//
//  Copyright (c) 2025 @mtzaquia
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

import Foundation
import SwiftUI
import IdentifiedCollections
import Testing
@testable import Formulaire

extension String: @retroactive LocalizedError {
    var localizedDescription: Self { self }
}

// MARK: - Test Models

@Observable @Formulaire
final class Address {
    var street: String = ""
    var city: String = ""

    func validate() {
        if street.isEmpty {
            addError("Street is required.", for: \.street)
        }
    }
}

@Observable @Formulaire
final class Phone: Identifiable {
    var id: String = UUID().uuidString
    var label: String = ""

    func validate() {
        if label.isEmpty {
            addError("Label is required.", for: \.label)
        }
    }
}

@Observable @Formulaire
final class Person {
    var name: String = ""
    var address: Address = Address()
    var phones: IdentifiedArrayOf<Phone> = []
    var optionalAddress: Address? = nil

    func validate() {
        if name.isEmpty {
            addError("Name is required.", for: \.name)
        }

        // Top-level error for empty list
        if phones.isEmpty {
            addError("At least one phone is required.", for: \.phones)
        }

        // Top-level error when optional is nil (to mirror recommended usage)
        if optionalAddress == nil {
            addError("An address is required.", for: \.optionalAddress)
        }

        // Reuse nested validation logic
        validate(\.address)
        validate(\.phones)
        validate(\.optionalAddress)
    }
}

@Suite("Formulaire Validation and Focus Path Tests")
struct FormulaireValidationAndFocusTests {
    // MARK: Basic validator behavior
    @Test("addError attaches using field label and clearAllErrors/hasErrors work")
    func testValidatorBasics() async throws {
        let addr = Address()
        #expect(addr.__validator.errors.isEmpty)
        addr.addError("X", for: \.city)
        #expect(addr.__validator.hasErrors())
        #expect(addr.__validator.errors.keys.contains("city"))

        addr.__validator.clearAllErrors()
        #expect(!addr.__validator.hasErrors())
        #expect(addr.__validator.errors.isEmpty)
    }

    // MARK: Field subscript get/set
    @Test("subscript(field:) correctly gets and sets values")
    func testFieldSubscriptGetSet() async throws {
        var p = Person()
        // Get field metadata from generated __fields
        let numberField = Person.__fields.name
        // Get
        #expect(p[field: numberField] == "")
        // Set
        p[field: numberField] = "Alice"
        #expect(p.name == "Alice")

        // Nested object field access
        let streetField = Person.__fields.address
        let nested = p[field: streetField]
        nested.street = "Main"
        // Assign back via set to ensure setter path works on Root
        p[field: streetField] = nested
        #expect(p.address.street == "Main")
    }

    // MARK: Nested subject validation
    @Test("nested subject validation prefixes keys with parent path")
    func testNestedSubjectValidation() async throws {
        let p = Person()
        p.name = "Alice" // avoid top-level name error
        p.address.street = "" // force nested error
        p.phones = [] // force top-level list error
        p.validate()
        let keys = Set(p.__validator.errors.keys)

        // Expect nested error for address.street
        #expect(keys.contains("address.street"))
        // Expect top-level error for empty list
        #expect(keys.contains("phones"))
        // No phone item errors because list is empty
        #expect(!keys.contains(where: { $0.hasPrefix("phones[") }))
    }

    // MARK: Nested list validation
    @Test("nested list validation composes keys with indexed parent prefix")
    func testNestedListValidation() async throws {
        let p = Person()
        p.name = "Alice"
        p.address.street = "Elm"

        // Populate two phones with empty labels to trigger nested errors
        let ph1 = Phone(); ph1.label = ""
        let ph2 = Phone(); ph2.label = ""
        p.phones = [ph1, ph2]
        p.validate()
        let keys = Set(p.__validator.errors.keys)

        // There should be no top-level phones error (list is not empty)
        #expect(!keys.contains("phones"))

        // Expect nested errors for each phone with index-like suffix [hash].label
        let k1 = "phones[\(ph1.id.hashValue)].label"
        let k2 = "phones[\(ph2.id.hashValue)].label"
        #expect(keys.contains(k1))
        #expect(keys.contains(k2))
    }

    // MARK: Optional nested subject behavior
    @Test("optional nested subject: nil -> top-level error only; present -> nested errors")
    func testOptionalNestedBehavior() async throws {
        // Case 1: nil optionalAddress
        do {
            let p = Person()
            p.name = "Bob"
            p.address.street = "Oak"
            p.optionalAddress = nil
            p.validate()
            let keys = Set(p.__validator.errors.keys)
            #expect(keys.contains("optionalAddress"))
            #expect(!keys.contains("optionalAddress.street"))
        }

        // Case 2: present optionalAddress with invalid nested field
        do {
            let p = Person()
            p.name = "Bob"
            p.address.street = "Oak"
            let opt = Address(); opt.street = "" // invalid
            p.optionalAddress = opt
            p.validate()
            let keys = Set(p.__validator.errors.keys)
            #expect(!keys.contains("optionalAddress"))
            #expect(keys.contains("optionalAddress.street"))
        }
    }

    // MARK: Idempotency of validation
    @Test("running validate() twice produces the same set of keys (no duplication)")
    func testIdempotentValidationProducesSameKeys() async throws {
        let p = Person()
        // Intentionally leave invalid to accumulate all top-level + nested address error
        p.name = ""                    // triggers name error
        p.address.street = ""          // triggers nested address.street error
        p.phones = []                   // triggers top-level phones error
        p.optionalAddress = nil         // triggers top-level optionalAddress error

        p.validate()
        let keys1 = Set(p.__validator.errors.keys)

        // Run validate again without clearing
        p.validate()
        let keys2 = Set(p.__validator.errors.keys)

        let expected: Set<String> = [
            "name",
            "phones",
            "optionalAddress",
            "address.street"
        ]
        #expect(keys1 == expected)
        #expect(keys2 == expected)
    }

    // MARK: Fixing all fields and re-validating leaves no errors
    @Test("fixing invalid fields then clearing and revalidating removes all errors")
    func testFixingAllErrorsResultsInNoErrorsAfterClearAndRevalidate() async throws {
        let p = Person()
        // Start invalid
        p.name = ""
        p.address.street = ""
        p.phones = []
        p.optionalAddress = nil
        p.validate()
        #expect(!p.__validator.errors.isEmpty)

        // Fix everything
        p.name = "Zoe"
        p.address.street = "Pine"
        let addr = Address(); addr.street = "Birch"; addr.city = "Springfield"
        p.optionalAddress = addr
        let ph = Phone(); ph.label = "Home"
        p.phones = [ph]

        // Clear and re-validate to recompute errors
        p.__validator.clearAllErrors()
        p.validate()
        #expect(p.__validator.errors.isEmpty)
    }

    // MARK: Reordering list items should not change error keys (id-based prefix)
    @Test("reordering phones keeps nested error keys stable (id-based)")
    func testPhoneReorderingDoesNotChangeErrorKeys() async throws {
        let p = Person()
        p.name = "Alice"
        p.address.street = "Elm"

        let ph1 = Phone(); ph1.label = ""  // invalid
        let ph2 = Phone(); ph2.label = ""  // invalid
        p.phones = [ph1, ph2]

        p.validate()
        let keyA1 = "phones[\(ph1.id.hashValue)].label"
        let keyA2 = "phones[\(ph2.id.hashValue)].label"
        let keysA = Set(p.__validator.errors.keys)
        #expect(keysA.contains(keyA1))
        #expect(keysA.contains(keyA2))

        // Reorder the phones
        p.phones = [ph2, ph1]
        p.__validator.clearAllErrors()
        p.validate()
        let keysB = Set(p.__validator.errors.keys)
        #expect(keysB.contains(keyA1))
        #expect(keysB.contains(keyA2))
        #expect(keysA == keysB)
    }

    // MARK: Mixed valid and invalid items in list
    @Test("only invalid phone entries produce nested errors")
    func testMixedValidInvalidPhonesOnlyInvalidHaveErrors() async throws {
        let p = Person()
        p.name = "Alice"
        p.address.street = "Elm"

        let invalid = Phone(); invalid.label = ""
        let valid = Phone(); valid.label = "Work"
        p.phones = [invalid, valid]

        p.validate()
        let keys = Set(p.__validator.errors.keys)
        #expect(!keys.contains("phones"))
        #expect(keys.contains("phones[\(invalid.id.hashValue)].label"))
        #expect(!keys.contains("phones[\(valid.id.hashValue)].label"))
    }

    // MARK: Optional becomes valid after being nil
    @Test("optionalAddress: nil first (top-level error), then valid removes errors")
    func testOptionalAddressBecomesValidRemovesTopLevelError() async throws {
        let p = Person()
        p.name = "Bob"
        p.address.street = "Oak"
        p.optionalAddress = nil
        p.validate()
        #expect(Set(p.__validator.errors.keys).contains("optionalAddress"))

        // Make it valid
        let a = Address(); a.street = "Main"; a.city = "Town"
        p.optionalAddress = a
        p.__validator.clearAllErrors()
        p.validate()
        let keys = Set(p.__validator.errors.keys)
        #expect(!keys.contains("optionalAddress"))
        #expect(!keys.contains("optionalAddress.street"))
    }

    // MARK: Focus order with dynamic IdentifiedArray ids
    @Test("focus order follows IdentifiedArray ids in the provided field list")
    func testFocusOrderWithIdentifiedArrayIds() async throws {
        let ph1 = Phone()
        let ph2 = Phone()

        let fields = [
            "name",
            "phones[\(ph1.id.hashValue)].label",
            "phones[\(ph2.id.hashValue)].label",
            "address.street"
        ]

        #expect(FormulaireView<Person, EmptyView>.nextFocusId(in: fields, current: "name") == fields[1])
        #expect(FormulaireView<Person, EmptyView>.nextFocusId(in: fields, current: fields[1]) == fields[2])
        #expect(FormulaireView<Person, EmptyView>.previousFocusId(in: fields, current: fields[2]) == fields[1])
        #expect(FormulaireView<Person, EmptyView>.previousFocusId(in: fields, current: "name") == nil)
        #expect(FormulaireView<Person, EmptyView>.nextFocusId(in: fields, current: "address.street") == nil)
    }

    @Test("focus order respects list reordering with new dynamic ids")
    func testFocusOrderWithReorderedIdentifiedArrayIds() async throws {
        let ph1 = Phone()
        let ph2 = Phone()

        let initial = [
            "name",
            "phones[\(ph1.id.hashValue)].label",
            "phones[\(ph2.id.hashValue)].label",
            "address.street"
        ]

        let reordered = [
            "name",
            "phones[\(ph2.id.hashValue)].label",
            "phones[\(ph1.id.hashValue)].label",
            "address.street"
        ]

        #expect(FormulaireView<Person, EmptyView>.nextFocusId(in: initial, current: "name") == initial[1])
        #expect(FormulaireView<Person, EmptyView>.nextFocusId(in: reordered, current: "name") == reordered[1])
        #expect(FormulaireView<Person, EmptyView>.previousFocusId(in: reordered, current: reordered[2]) == reordered[1])
    }
}
