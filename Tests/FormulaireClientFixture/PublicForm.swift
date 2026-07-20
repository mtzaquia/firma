import Formulaire
import Foundation
import Observation

@MainActor
@Observable @Formulaire
public final class PublicForm {
    public var name: String = ""
    public var acceptsTerms: Bool = false

    public init() {}

    public func validate() {
        if name.isEmpty {
            addError(PublicFormError.nameRequired, for: \.name)
        }
    }
}

public enum PublicFormError: LocalizedError {
    case nameRequired

    public var errorDescription: String? { "Name is required" }
}
