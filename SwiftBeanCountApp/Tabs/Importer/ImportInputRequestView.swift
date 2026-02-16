//
//  ImportInputRequestView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-12-12.
//

import SwiftBeanCountImporter
import SwiftUI

protocol ImportInputRequestViewDataProvider {
    var input: (String, String, ImporterInputRequestType)? { get } // swiftlint:disable:this large_tuple

    func input(_ value: String)
    func cancelInput()
}

private struct PreviewImportInputRequestViewDataProvider: ImportInputRequestViewDataProvider {

    let input: (String, String, ImporterInputRequestType)? // swiftlint:disable:this large_tuple

    func input(_: String) {
        // Do nothing
    }

    func cancelInput() {
        // Do nothing
    }
}

struct ImportInputRequestView: View {

    var importManager: any ImportInputRequestViewDataProvider

    private var disableOkButton: Bool {
        var disable = false
        if case .choice = importManager.input!.2, input.isEmpty {
            disable = true
        }
        return disable
    }

    @State private var input = ""

    var body: some View {
        let type = importManager.input!.2
        let text = "\(type == .bool ? importManager.input!.1 : "Please provide the requested information") for the following import: \(importManager.input!.0)"
        VStack(alignment: .leading) {
#if !os(macOS)
            Text("Importer Input").font(.largeTitle).bold().padding(.vertical)
#endif
            Text(text).padding(.bottom).padding(.trailing)
            if .bool != type {
                Text(importManager.input!.1).font(.headline)
            }
            switch type {
            case .bool:
                EmptyView() // No other UI, just the buttons
            case .otp:
                TextField(importManager.input!.1, text: $input).textContentType(.oneTimeCode)
            case .secret:
                SecureField(importManager.input!.1, text: $input).textContentType(.password)
            case let .text(suggestions):
                textInputView(suggestions)
            case let .choice(choices):
                Picker(importManager.input!.1, selection: $input) { ForEach(choices, id: \.self) { Text($0).tag($0) } }
            }
            HStack {
                Spacer()
                if type == .bool {
                    Button("No") { importManager.input("false") }
                    Button("Yes") { importManager.input("true") }
                } else {
                    Button("Cancel") { importManager.cancelInput() }
                    Button("OK") { importManager.input(input) }.disabled(disableOkButton).buttonStyle(.borderedProminent)
                }
            }.padding(.top).buttonStyle(.bordered)
            Spacer()
        }
            .padding()
            .interactiveDismissDisabled()
    }

    func textInputView(_ suggestions: [String]) -> some View {
        TextField(importManager.input!.1, text: $input)
#if os(macOS)
            .textInputSuggestions {
                if !suggestions.contains(where: { $0.lowercased() == input.lowercased() }) {
                    ForEach(suggestions, id: \.self) { Text($0).textInputCompletion($0) }
                }
            }
#endif
    }

}

struct ImportInputRequestView_Previews: PreviewProvider {

    static var previews: some View {
        ImportInputRequestView(importManager:
            PreviewImportInputRequestViewDataProvider(
                input: ("Importer Name", "Input text", .secret)
            )
        )

        ImportInputRequestView(importManager:
            PreviewImportInputRequestViewDataProvider(
                input: ("Importer Name", "Input text", .text(["suggestion1 a little bit longer longer longer longer", "suggestion2"]))
            )
        )

        ImportInputRequestView(importManager:
            PreviewImportInputRequestViewDataProvider(
                input: ("Importer Name", "Input text", .choice(["choice1", "choice2"]))
            )
        )

        ImportInputRequestView(importManager:
            PreviewImportInputRequestViewDataProvider(
                input: ("Importer Name", "Input choice", .bool)
            )
        )

        ImportInputRequestView(importManager:
            PreviewImportInputRequestViewDataProvider(
                input: ("Importer Name", "Input text", .otp)
            )
        )
    }
}
