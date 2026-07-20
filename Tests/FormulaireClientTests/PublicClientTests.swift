import Formulaire
import FormulaireClientFixture
import Testing

@Suite("External client surface")
struct PublicClientTests {
    @Test("public generated fields are visible from another module")
    func publicFields() {
        let name: FieldPath<PublicForm, String> = \.name
        let terms: FieldPath<PublicForm, Bool> = \.acceptsTerms
        let form = PublicForm()

        #expect(PublicForm.__fields[keyPath: name] == PublicForm.__fields.name)
        #expect(PublicForm.__fields[keyPath: terms] == PublicForm.__fields.acceptsTerms)
        #expect(!form.runValidation().isValid)
    }
}

