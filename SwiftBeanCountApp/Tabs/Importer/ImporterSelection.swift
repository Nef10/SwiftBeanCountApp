//
//  Importer.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-12-01.
//

import OSLog
import SwiftBeanCountImporter
import SwiftUI

struct ImporterSelection: View {

    @EnvironmentObject var ledger: LedgerManager

    @Environment(\.openWindow)
    var openWindow

    @Binding private var imports: [ImportType]

    @State private var fileImport = [URL]()
    @State private var textImport = [(String, String)]() // transaction, balance
    @State private var downloadImport: [Bool] = Array(repeating: false, count: ImporterFactory.downloadImporterNames.count)
    @State private var isDocumentPickerPresented = false
    @State private var showTextInputSheet = false
    @State private var textInputTransaction = ""
    @State private var textInputBalance = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text("Select Input").font(.headline)
            Grid(alignment: .leadingFirstTextBaseline) {
                GridRow {
                    Button("Add File(s)") { isDocumentPickerPresented = true }
                    Text("\(fileImport.count) files selected")
                }
                GridRow {
                    Button("Add Text") { showTextInputSheet = true }
                    Text("\(textImport.count) texts added")
                }
            }.padding(.leading).padding(.bottom)

            Text("Download Input").font(.headline)
            VStack(alignment: .leading) {
                ForEach(Array(ImporterFactory.downloadImporterNames.enumerated()), id: \.element) { index, downloadImporter in
                    Toggle(downloadImporter, isOn: $downloadImport[index])
                }.padding(.leading)
            }.padding(.bottom)

            Spacer()
            HStack {
                Button("?") { openWindow(id: "importer-help") }.buttonBorderShape(.circle)
                Spacer()
                Button("Reset") {
                    resetInput()
                }.disabled(fileImport.isEmpty && textImport.isEmpty && downloadImport.allSatisfy { !$0 })
                if ledger.loadingLedger {
                    ProgressView().controlSize(.small).padding(5)
                } else {
                    Button("Generate Transactions") { generate() } .disabled(fileImport.isEmpty && textImport.isEmpty && downloadImport.allSatisfy { !$0 })
                }
            }
        }
        .padding()
        .fileImporter(
            isPresented: $isDocumentPickerPresented,
            allowedContentTypes: [.commaSeparatedText, .folder],
            allowsMultipleSelection: true,
            onCompletion: selectFilesFromURLs
        )
        .alert("Error", isPresented: $showErrorAlert) { Button("OK") { /* empty */ } } message: { Text(errorMessage) }
        .sheet(isPresented: $showTextInputSheet) {
            VStack {
                HStack {
                    VStack {
                        Text("Transaction").font(.headline)
                        TextEditor(text: $textInputTransaction).frame(minHeight: 400)
                    }
                    VStack {
                        Text("Balance").font(.headline)
                        TextEditor(text: $textInputBalance).frame(minHeight: 400)
                    }
                }
                HStack {
                    Spacer()
                    Button("Cancel") { closeTextInputSheet() }
                    Button("Add") { addAndCloseTextInput() }
                }.padding(.top)
            }.padding()
        }
    }

    init(_ imports: Binding<[ImportType]>) {
        self._imports = imports
    }

    private func generate() {
        let importTypes = fileImport.map { ImportType.csv($0) }
            + textImport.map { ImportType.text($0.0, $0.1) }
            + downloadImport.enumerated().compactMap { $0.element ? ImportType.download(ImporterFactory.downloadImporterNames[$0.offset]) : nil }
        imports = importTypes
    }

    private func resetInput() {
        fileImport = []
        textImport = []
        downloadImport = Array(repeating: false, count: ImporterFactory.downloadImporterNames.count)
    }

    private func addAndCloseTextInput() {
        let transactionString = textInputTransaction.trimmingCharacters(in: .whitespacesAndNewlines)
        let balanceString = textInputBalance.trimmingCharacters(in: .whitespacesAndNewlines)
        if !transactionString.isEmpty || !balanceString.isEmpty {
            textImport.append((textInputTransaction, textInputBalance))
        }
        closeTextInputSheet()
    }

    private func closeTextInputSheet() {
        showTextInputSheet = false
        textInputTransaction = ""
        textInputBalance = ""
    }

    private func selectFilesFromURLs(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else {
                    errorMessage = "Could not access file"
                    showErrorAlert = true
                    return
                }
                if !url.hasDirectoryPath {
                    fileImport.append(url)
                } else {
                    let enumerator = FileManager.default.enumerator(at: url,
                                                                    includingPropertiesForKeys: [.isDirectoryKey],
                                                                    options: [.skipsHiddenFiles]) { _, error -> Bool in
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                        return true
                    }!
                    var urls = [URL]()
                    for case let fileURL as URL in enumerator where !fileURL.hasDirectoryPath && fileURL.pathExtension.lowercased() == "csv" {
                        urls.append(url)
                    }
                    fileImport.append(contentsOf: urls)
                }
                url.stopAccessingSecurityScopedResource()
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

#Preview {
    ImporterSelection(.constant([])).environmentObject(LedgerManager(URL(fileURLWithPath: "/Users/User/Download/Test.beancount")))
}
