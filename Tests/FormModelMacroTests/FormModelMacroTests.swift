import FormModelMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class FormModelMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = ["FormModel": FormModelMacro.self]

    func testPublicGenericAndMultiBindingExpansion() {
        assertMacroExpansion(
            """
            @Observable @FormModel
            public final class Model<Value> {
                public var name: String = ""
                var count = 0, enabled = true
                var inferred = 0, explicit: Bool = true
                var values: [Value] = []
                public func validate(_ validation: ValidationContext<Model<Value>>) {}
            }
            """,
            expandedSource: """
            @Observable
            public final class Model<Value> {
                public var name: String = ""
                var count = 0, enabled = true
                var inferred = 0, explicit: Bool = true
                var values: [Value] = []
                public func validate(_ validation: ValidationContext<Model<Value>>) {}

                public struct Fields {
                    public var name: FirmaField<Model<Value>, String> {
                        FirmaField(label: "name", keyPath: \\Model<Value>.name)
                    }
                    let count = FirmaField(label: "count", keyPath: \\Model<Value>.count)
                    let enabled = FirmaField(label: "enabled", keyPath: \\Model<Value>.enabled)
                    let inferred = FirmaField(label: "inferred", keyPath: \\Model<Value>.inferred)
                    var explicit: FirmaField<Model<Value>, Bool> {
                        FirmaField(label: "explicit", keyPath: \\Model<Value>.explicit)
                    }
                    var values: FirmaField<Model<Value>, [Value]> {
                        FirmaField(label: "values", keyPath: \\Model<Value>.values)
                    }
                }

                public static var __fields: Fields { Fields() }

                @ObservationIgnored
                public let __validator = Validator()
            }

            extension Model: Firma {
            }
            """,
            macros: macros
        )
    }

    func testOpenClassUsesPublicGeneratedWitnesses() {
        assertMacroExpansion(
            """
            @Observable @FormModel
            open class OpenModel {
                public var name: String = ""
                public func validate(_ validation: ValidationContext<OpenModel>) {}
            }
            """,
            expandedSource: """
            @Observable
            open class OpenModel {
                public var name: String = ""
                public func validate(_ validation: ValidationContext<OpenModel>) {}

                public struct Fields {
                    public var name: FirmaField<OpenModel, String> {
                        FirmaField(label: "name", keyPath: \\OpenModel.name)
                    }
                }

                public static var __fields: Fields { Fields() }

                @ObservationIgnored
                public let __validator = Validator()
            }

            extension OpenModel: Firma {
            }
            """,
            macros: macros
        )
    }

    func testRequiresClassAndObservable() {
        assertMacroExpansion(
            """
            @FormModel
            struct ValueModel {}
            """,
            expandedSource: """
            struct ValueModel {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "@FormModel can only be applied to classes.", line: 1, column: 1)
            ],
            macros: macros
        )

        assertMacroExpansion(
            """
            @FormModel
            final class ReferenceModel {
                var value = ""
                func validate(_ validation: ValidationContext<ReferenceModel>) {}
            }
            """,
            expandedSource: """
            final class ReferenceModel {
                var value = ""
                func validate(_ validation: ValidationContext<ReferenceModel>) {}
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Types using @FormModel must also be annotated with @Observable.",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }
}
