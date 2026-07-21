import FirmaMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class FirmaMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = ["Firma": FirmaMacro.self]

    func testPublicGenericAndMultiBindingExpansion() {
        assertMacroExpansion(
            """
            @Observable @Firma
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
            @Observable @Firma
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
            @Firma
            struct ValueModel {}
            """,
            expandedSource: """
            struct ValueModel {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Firma can only be applied to classes.", line: 1, column: 1)
            ],
            macros: macros
        )

        assertMacroExpansion(
            """
            @Firma
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
                    message: "Types using @Firma must also be annotated with @Observable.",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }
}
