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

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct FormulaireDiagnosticMessage: DiagnosticMessage {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    init(id: String, message: String, severity: DiagnosticSeverity = .error) {
        self.message = message
        self.severity = severity
        self.diagnosticID = MessageID(domain: "FormulaireMacro", id: id)
    }
}

public struct FormulaireMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self), hasObservableAttribute(declaration) else {
            return []
        }

        if declaration.inheritanceClause?.inheritedTypes.contains(where: {
            $0.type.trimmedDescription.split(separator: ".").last == "Formulaire"
        }) == true {
            return []
        }

        return [try ExtensionDeclSyntax("extension \(type.trimmed): Formulaire {}")]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDeclaration = declaration.as(ClassDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: Syntax(declaration),
                message: FormulaireDiagnosticMessage(
                    id: "class-only",
                    message: "@Formulaire can only be applied to classes."
                )
            ))
            return []
        }

        guard hasObservableAttribute(declaration) else {
            context.diagnose(Diagnostic(
                node: Syntax(declaration),
                message: FormulaireDiagnosticMessage(
                    id: "requires-observable",
                    message: "Types using @Formulaire must also be annotated with @Observable."
                )
            ))
            return []
        }

        let typeAccess = accessLevel(of: declaration.modifiers)
        let witnessAccess = exportedAccess(typeAccess)
        let typeName = classDeclaration.name.text
        let genericArguments = classDeclaration.genericParameterClause?.parameters
            .map(\.name.text)
            .joined(separator: ", ")
        let typeReference = genericArguments.map { "\(typeName)<\($0)>" } ?? typeName

        var generatedFields: [String] = []

        for member in declaration.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self), isInstanceVariable(variable) else {
                continue
            }

            let fallbackType = variable.bindings.last?.typeAnnotation?.type.trimmedDescription
            for binding in variable.bindings where isWritable(binding) {
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                    context.diagnose(Diagnostic(
                        node: Syntax(binding.pattern),
                        message: FormulaireDiagnosticMessage(
                            id: "unsupported-pattern",
                            message: "Formulaire fields must use a simple property name."
                        )
                    ))
                    continue
                }

                let propertyAccess = exportedAccess(accessLevel(of: variable.modifiers))
                let type = binding.typeAnnotation?.type.trimmedDescription
                    ?? (binding.initializer == nil ? fallbackType : nil)

                if !propertyAccess.isEmpty, type == nil {
                    context.diagnose(Diagnostic(
                        node: Syntax(binding),
                        message: FormulaireDiagnosticMessage(
                            id: "public-field-requires-type",
                            message: "Public Formulaire fields require an explicit type annotation so their generated field metadata can also be public."
                        )
                    ))
                    continue
                }

                let accessPrefix = propertyAccess.isEmpty ? "" : "\(propertyAccess) "
                if let type {
                    generatedFields.append(
                        "\(accessPrefix)var \(identifier): FormulaireField<\(typeReference), \(type)> { FormulaireField(label: \"\(identifier)\", keyPath: \\\(typeReference).\(identifier)) }"
                    )
                } else {
                    generatedFields.append(
                        "let \(identifier) = FormulaireField(label: \"\(identifier)\", keyPath: \\\(typeReference).\(identifier))"
                    )
                }
            }
        }

        let witnessPrefix = witnessAccess.isEmpty ? "" : "\(witnessAccess) "
        let fields = generatedFields.joined(separator: "\n")
        return [DeclSyntax(stringLiteral:
            """
            \(witnessPrefix)struct Fields {
            \(fields)
            }

            \(witnessPrefix)static var __fields: Fields { Fields() }

            @ObservationIgnored
            \(witnessPrefix)let __validator = Validator()
            """
        )]
    }
}

private extension FormulaireMacro {
    static func hasObservableAttribute(_ declaration: some DeclGroupSyntax) -> Bool {
        declaration.attributes.contains { element in
            guard let attribute = element.as(AttributeSyntax.self) else { return false }
            return attribute.attributeName.trimmedDescription.split(separator: ".").last == "Observable"
        }
    }

    static func accessLevel(of modifiers: DeclModifierListSyntax) -> String {
        let supported = ["open", "public", "package", "internal", "fileprivate", "private"]
        return modifiers.first(where: { supported.contains($0.name.text) })?.name.text ?? ""
    }

    static func exportedAccess(_ access: String) -> String {
        switch access {
        case "open", "public": "public"
        case "package": "package"
        default: ""
        }
    }

    static func isInstanceVariable(_ variable: VariableDeclSyntax) -> Bool {
        guard variable.bindingSpecifier.tokenKind == .keyword(.var) else { return false }
        return !variable.modifiers.contains(where: {
            $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        })
    }

    static func isWritable(_ binding: PatternBindingSyntax) -> Bool {
        guard let accessorBlock = binding.accessorBlock else {
            return true
        }

        switch accessorBlock.accessors {
        case .getter:
            return false
        case .accessors(let accessors):
            return accessors.contains { accessor in
                let name = accessor.accessorSpecifier.text
                return name == "set" || name == "_modify" || name == "willSet" || name == "didSet"
            }
        }
    }
}
