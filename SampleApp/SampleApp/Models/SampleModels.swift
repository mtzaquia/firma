import Firma
import Foundation
import Observation

@Observable @FormObject
final class ControlsFormModel {
    var fullName: String = ""
    var email: String = ""
    var age: Int = 18
    var receivesUpdates: Bool = false
    var startDate: Date = Date(timeIntervalSince1970: 1_735_689_600)
    var referralCode: String = ""

    func validate() {
        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addError("Full name is required", for: \.fullName)
        }
        if !email.contains("@") {
            addError("Enter a valid email address", for: \.email)
        }
        if age < 18 {
            addError("You must be at least 18", for: \.age)
        }
        if !referralCode.isEmpty, referralCode.count < 4 {
            addError("Referral codes contain at least four characters", for: \.referralCode)
        }
    }
}

@Observable @FormObject
final class CountryFormModel {
    var code: String = ""

    func validate() {
        if code.count != 2 { addError("Use a two-letter country code", for: \.code) }
    }
}

@Observable @FormObject
final class AddressFormModel {
    var street: String = ""
    var city: String = ""
    var country: CountryFormModel = CountryFormModel()

    func validate() {
        if street.isEmpty { addError("Street is required", for: \.street) }
        if city.isEmpty { addError("City is required", for: \.city) }
        validate(\.country)
    }
}

@Observable @FormObject
final class AccountFormModel {
    var username: String = ""
    var primaryAddress: AddressFormModel = AddressFormModel()
    var alternateAddress: AddressFormModel?

    func validate() {
        if username.count < 3 { addError("Username must contain at least three characters", for: \.username) }
        if alternateAddress == nil { addError("Add an alternate address", for: \.alternateAddress) }
        validate(\.primaryAddress)
        validate(\.alternateAddress)
    }
}

@Observable @FormObject
final class AttendeeFormModel: Identifiable {
    var id: String
    var name: String = ""
    var ticketCount: Int = 1
    var needsAccessibilitySupport: Bool = false

    init(id: String) { self.id = id }

    func validate() {
        if name.isEmpty { addError("Attendee name is required", for: \.name) }
    }
}

@Observable @FormObject
final class EventFormModel {
    var eventName: String = "Sample meetup"
    var attendees: IdentifiedArrayOf<AttendeeFormModel> = []

    func validate() {
        if eventName.isEmpty { addError("Event name is required", for: \.eventName) }
        if attendees.isEmpty { addError("Add at least one attendee", for: \.attendees) }
        validate(\.attendees)
    }
}
