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
import SwiftSyntaxMacros
import SwiftSyntax
import SwiftDiagnostics

struct FormulaireDiagnosticMessage: DiagnosticMessage {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    init(message: String, severity: DiagnosticSeverity = .warning) {
        self.message = message
        self.severity = severity
        self.diagnosticID = MessageID(domain: "FormulaireMacro", id: "FormulaireDiagnostic")
    }
}

struct FormulaireFixItMessage: FixItMessage {
    let message: String
    let fixItID: MessageID

    init(message: String, id: String = "FormulaireFixIt") {
        self.message = message
        self.fixItID = MessageID(domain: "FormulaireMacro", id: id)
    }
}

public struct FormulaireMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        if declaration.as(ClassDeclSyntax.self) == nil {
            context.diagnose(Diagnostic(
                node: Syntax(declaration),
                message: FormulaireDiagnosticMessage(
                    message: "@Formulaire can only be applied to classes.",
                    severity: .error
                )
            ))
            return []
        }

        if let inheritanceClause = declaration.inheritanceClause,
           inheritanceClause.inheritedTypes.contains(
            where: {
                ["Formulaire"].contains($0.type.trimmedDescription)
            }
           )
        {
            return []
        }

        return [
            try ExtensionDeclSyntax(
                "extension \(type.trimmed): Formulaire {}"
            )
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Ensure macro is only applied to classes
        if declaration.as(ClassDeclSyntax.self) == nil {
            context.diagnose(Diagnostic(
                node: Syntax(declaration),
                message: FormulaireDiagnosticMessage(
                    message: "@Formulaire can only be applied to classes.",
                    severity: .error
                )
            ))
            return []
        }

        // Determine access level of the attached type
        let accessLevels = ["open", "public", "internal", "private", "fileprivate"]
        let accessLevel = declaration.modifiers.first(where: { mod in
            accessLevels.contains(mod.name.text)
        })?.name.text ?? "internal"

        // Extract the type name from the declaration
        let typeName: String = (declaration.as(ClassDeclSyntax.self)?.name.text) ?? "Self"

        // Check if the type is annotated with @Observable
        let hasObservable = declaration.attributes.contains { attr in
            if let attrId = attr.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text {
                return attrId == "Observable"
            }
            return false
        }
        if !hasObservable {
            context.diagnose(Diagnostic(
                node: Syntax(declaration),
                message: FormulaireDiagnosticMessage(
                    message: "Types using @Formulaire should also be annotated with @Observable.",
                    severity: .error
                )
            ))
        }

        // Collect writable stored properties (exclude computed properties and immutable lets)
        let properties = declaration.memberBlock.members.compactMap { member -> VariableDeclSyntax? in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { return nil }

            // Exclude static/class properties
            if varDecl.modifiers.contains(where: { $0.name.text == "static" || $0.name.text == "class" }) {
                return nil
            }

            // Only consider `var` declarations (skip `let`)
            if varDecl.bindingSpecifier.tokenKind != .keyword(.var) {
                return nil
            }

            // We only support exactly one binding per declaration for now
            guard varDecl.bindings.count == 1, let binding = varDecl.bindings.first else { return nil }

            // Exclude computed properties: they have an accessor block without `set`
            if let accessorBlock = binding.accessorBlock {
                switch accessorBlock.accessors {
                case .accessors(let list):
                    // If there is a setter, it's writable; otherwise it's read-only computed
                    let hasSetter = list.contains(where: { accessor in
                        if case .keyword(let keyword) = accessor.accessorSpecifier.tokenKind {
                            return keyword == .set
                        }
                        return false
                    })
                    if !hasSetter { return nil }
                case .getter:
                    // Explicit getter-only
                    return nil
                }
            }

            // If there is no accessor block, it's a stored property (writable by default for `var`)
            return varDecl
        }

        // Emit an error if any property uses a plain Swift array ([T] or Array<T>) and propose a fix-it
        for varDecl in properties {
            guard let binding = varDecl.bindings.first,
                  let typeAnnotation = binding.typeAnnotation,
                  let typeAnnotationRaw = typeAnnotation.type.description
                .trimmingCharacters(in: .whitespacesAndNewlines) as String? else { continue }

            let isBracketArray = typeAnnotationRaw.hasPrefix("[") && typeAnnotationRaw.hasSuffix("]")
            let isGenericArray = typeAnnotationRaw.hasPrefix("Array<") && typeAnnotationRaw.hasSuffix(">")

            // Extract element type for fix-it
            var elementType: String? = nil
            if isBracketArray {
                let inner = String(typeAnnotationRaw.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                elementType = inner.isEmpty ? nil : inner
            } else if isGenericArray {
                let inner = String(typeAnnotationRaw.dropFirst("Array<".count).dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                elementType = inner.isEmpty ? nil : inner
            }

            if isBracketArray || isGenericArray {
                let message = FormulaireDiagnosticMessage(
                    message: "Formulaire does not support plain Swift arrays for form fields. Use IdentifiedArrayOf<Element> or IdentifiedArray<ID, Element> instead of [Element]/Array<Element>.",
                    severity: .error
                )

                if let elem = elementType {
                    let replacement = TypeSyntax(stringLiteral: "IdentifiedArrayOf<\(elem)> ")
                    let fixIt = FixIt(
                        message: FormulaireFixItMessage(message: "Replace with IdentifiedArrayOf<\(elem)>", id: "ReplaceArrayWithIdentifiedArray"),
                        changes: [
                            .replace(oldNode: Syntax(typeAnnotation.type), newNode: Syntax(replacement))
                        ]
                    )
                    let diagnostic = Diagnostic(node: Syntax(typeAnnotation.type), message: message, fixIts: [fixIt])
                    context.diagnose(diagnostic)
                } else {
                    context.diagnose(Diagnostic(
                        node: Syntax(varDecl),
                        message: message
                    ))
                }
            }
        }

        let fieldsStructProperties = properties.compactMap { varDecl -> String? in
            guard let binding = varDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                return nil
            }
            // Require a type annotation to generate a proper field type
            guard let typeAnnotation = binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines), !typeAnnotation.isEmpty else {
                return nil
            }
            return "var \(identifier): FormulaireField<\(typeName), \(typeAnnotation)> { FormulaireField(label: \"\(identifier)\", keyPath: \\\((typeName)).\(identifier)) }"
        }.joined(separator: "\n        ")

        let fieldsStructDecl = DeclSyntax(stringLiteral:
            """
            \(accessLevel) struct Fields {
                \(fieldsStructProperties)
            }
            
            @ObservationIgnored
            \(accessLevel) static var __fields: Fields = Fields()
            \(accessLevel) var __validator = Validator<\(typeName)>()
            """
        )

        return [fieldsStructDecl]
    }
}

