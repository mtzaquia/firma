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

import Firma
import Foundation
import Observation

@Observable @FormModel
final class ControlsFormModel {
    var fullName: String = ""
    var email: String = ""
    var age: Int = 18
    var receivesUpdates: Bool = false
    var startDate: Date = Date(timeIntervalSince1970: 1_735_689_600)
    var referralCode: String = ""

    func validate(_ validation: ValidationContext<ControlsFormModel>) {
        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validation.addError("Full name is required", for: \.fullName)
        }
        if !email.contains("@") {
            validation.addError("Enter a valid email address", for: \.email)
        }
        if age < 18 {
            validation.addError("You must be at least 18", for: \.age)
        }
        if !referralCode.isEmpty, referralCode.count < 4 {
            validation.addError("Referral codes contain at least four characters", for: \.referralCode)
        }
    }
}

@Observable @FormModel
final class CountryFormModel {
    var code: String = ""

    func validate(_ validation: ValidationContext<CountryFormModel>) {
        if code.count != 2 { validation.addError("Use a two-letter country code", for: \.code) }
    }
}

@Observable @FormModel
final class AddressFormModel {
    var street: String = ""
    var city: String = ""
    var country: CountryFormModel = CountryFormModel()

    func validate(_ validation: ValidationContext<AddressFormModel>) {
        if street.isEmpty { validation.addError("Street is required", for: \.street) }
        if city.isEmpty { validation.addError("City is required", for: \.city) }
        validation.validate(\.country)
    }
}

@Observable @FormModel
final class AccountFormModel {
    var username: String = ""
    var primaryAddress: AddressFormModel = AddressFormModel()
    var alternateAddress: AddressFormModel?

    func validate(_ validation: ValidationContext<AccountFormModel>) {
        if username.count < 3 { validation.addError("Username must contain at least three characters", for: \.username) }
        if alternateAddress == nil { validation.addError("Add an alternate address", for: \.alternateAddress) }
        validation.validate(\.primaryAddress)
        validation.validate(\.alternateAddress)
    }
}

@Observable @FormModel
final class AttendeeFormModel: Identifiable {
    var id: String
    var name: String = ""
    var ticketCount: Int = 1
    var needsAccessibilitySupport: Bool = false

    init(id: String) { self.id = id }

    func validate(_ validation: ValidationContext<AttendeeFormModel>) {
        if name.isEmpty { validation.addError("Attendee name is required", for: \.name) }
    }
}

@Observable @FormModel
final class EventFormModel {
    var eventName: String = "Sample meetup"
    var attendees: IdentifiedArrayOf<AttendeeFormModel> = []

    func validate(_ validation: ValidationContext<EventFormModel>) {
        if eventName.isEmpty { validation.addError("Event name is required", for: \.eventName) }
        if attendees.isEmpty { validation.addError("Add at least one attendee", for: \.attendees) }
        validation.validate(\.attendees)
    }
}
