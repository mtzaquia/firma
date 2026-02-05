# Formulaire

A lightweight Swift library for building validated, focus-aware forms using Swift macros and SwiftUI. Formulaire provides helpers to render controls, manage focus, and surface validation errors.

![gif showcasing a simple invoice formulaire with validation and dynamic lists](https://github.com/user-attachments/assets/8b6b8ec9-d37a-466a-9a96-df7a06ecfe4f)
![gif showcasing a person formulaire with keyboard navigation](https://github.com/user-attachments/assets/867fcaab-73cd-43d0-a16e-a68bb2e7d6f4)

## Instalation

Formulaire is available via Swift Package Manager, and requires `Swift 6.2`.

```swift
dependencies: [
  .package(url: "https://github.com/mtzaquia/formulaire.git", from: "1.3.0"),
],
```

## Usage

### Getting Started

Annotate your form model class with `@Observable` and `@Formulaire`, and provide a `validate()` method. Leave it empty for no validation.

```swift
import Formulaire

@Observable @Formulaire
final class SignUpForm {
  var firstName: String = ""
  var lastName: String = ""
  var age: Int = 18
  var preferences: IdentifiedArrayOf<Preference> = [
    Preference("News about cats", isEnabled: false),
    Preference("News about dogs", isEnabled: false)
  ]

  func validate() {
    if firstName.isEmpty {
      addError(MissingRequiredFieldError(), for: \.firstName)
    }

    if lastName.isEmpty {
      addError(MissingRequiredFieldError(), for: \.lastName)
    }
    
    if preferences.count(where: { $0.isEnabled }) == .zero {
      addError(AtLeastOneError(), for: \.preferences)
    }
    
    // This would validate the `Preference` type using its `validate()` function.
    // validate(\.preferences)
  }
}

@Observable @Formulaire
final class Preference {
  var name: String
  var isEnabled: Bool
  
  func validate() {
    // Compose validation of complex models by breaking them down, like here.
  }
}
```

### Building UI

Formulaire ships with a small set of SwiftUI helpers to wire your form to UI controls while managing focus and errors. You can create your own controls using `form.control(for:focusable:content:)` or display custom content with error-awareness using `form.content(for:content:)`.

Focus and keyboard navigation is managed automatically and supports dynamically-built forms and lists.

```swift
import Formulaire
import SwiftUI

struct SignUpView: View {
  @State private var form = SignUpForm()

  var body: some View {
    FormulaireView(editing: $form) { form in
      form.textField(for: \.firstName, label: "First name")
      form.textField(for: \.lastName, label: "Last name")
      form.stepper(for: \.age, label: "Age", step: 1, range: 0...120)
      
      form.content(for: \.preferences) { error in 
        Section {
          ForEach(invoice.preferences) { preference in
            let scoped = form.scope(\.preferences, for: preference)
            scoped.toggle(for: \.isEnabled, label: preference.name)
          }
        } footer: {
          if let error {
            Text(error.localizedDescription)
          }
        }
      }
      
      // Use a default submit button...
      form.submitButton("Create Account") {
        // Handle success
        print("Submitted")
      }

      // ... or handle it with your own logic.
      Button("Done!") { 
        let success = form.validate()
        if success {
          // handle success
        }
      }
    }
    .padding()
  }
}
```

## License

Copyright (c) 2025 @mtzaquia

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
