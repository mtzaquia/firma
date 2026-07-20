import FormulaireMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class FormulaireMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = ["Formulaire": FormulaireMacro.self]

    func testPublicGenericAndMultiBindingExpansion() {
        assertMacroExpansion(
            """
            @Observable @Formulaire
            public final class Model<Value> {
                public var name: String = ""
                var count = 0, enabled = true
                var inferred = 0, explicit: Bool = true
                var values: [Value] = []
                public func validate() {}
            }
            """,
            expandedSource: """
            @Observable
            public final class Model<Value> {
                public var name: String = ""
                var count = 0, enabled = true
                var inferred = 0, explicit: Bool = true
                var values: [Value] = []
                public func validate() {}

                public struct Fields {
                    public var name: FormulaireField<Model<Value>, String> {
                        FormulaireField(label: "name", keyPath: \\Model<Value>.name)
                    }
                    let count = FormulaireField(label: "count", keyPath: \\Model<Value>.count)
                    let enabled = FormulaireField(label: "enabled", keyPath: \\Model<Value>.enabled)
                    let inferred = FormulaireField(label: "inferred", keyPath: \\Model<Value>.inferred)
                    var explicit: FormulaireField<Model<Value>, Bool> {
                        FormulaireField(label: "explicit", keyPath: \\Model<Value>.explicit)
                    }
                    var values: FormulaireField<Model<Value>, [Value]> {
                        FormulaireField(label: "values", keyPath: \\Model<Value>.values)
                    }
                }

                public static var __fields: Fields { Fields() }

                @ObservationIgnored
                public let __validator = Validator()
            }

            extension Model: Formulaire {
            }
            """,
            macros: macros
        )
    }

    func testOpenClassUsesPublicGeneratedWitnesses() {
        assertMacroExpansion(
            """
            @Observable @Formulaire
            open class OpenModel {
                public var name: String = ""
                public func validate() {}
            }
            """,
            expandedSource: """
            @Observable
            open class OpenModel {
                public var name: String = ""
                public func validate() {}

                public struct Fields {
                    public var name: FormulaireField<OpenModel, String> {
                        FormulaireField(label: "name", keyPath: \\OpenModel.name)
                    }
                }

                public static var __fields: Fields { Fields() }

                @ObservationIgnored
                public let __validator = Validator()
            }

            extension OpenModel: Formulaire {
            }
            """,
            macros: macros
        )
    }

    func testRequiresClassAndObservable() {
        assertMacroExpansion(
            """
            @Formulaire
            struct ValueModel {}
            """,
            expandedSource: """
            struct ValueModel {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Formulaire can only be applied to classes.", line: 1, column: 1)
            ],
            macros: macros
        )

        assertMacroExpansion(
            """
            @Formulaire
            final class ReferenceModel {
                var value = ""
                func validate() {}
            }
            """,
            expandedSource: """
            final class ReferenceModel {
                var value = ""
                func validate() {}
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Types using @Formulaire must also be annotated with @Observable.",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }
}
