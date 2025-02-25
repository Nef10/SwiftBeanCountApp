//
//  ImportManager.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-12-06.
//

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
import Foundation
import OSLog
import SimpleKeychain
@preconcurrency import SwiftBeanCountImporter
import SwiftBeanCountModel

private enum ImportPhase {
    case setupImporters
    case importing
    case done
}

class ImportManager: ObservableObject, ImportInputRequestViewDataProvider {

    @Published var resultLedger = Ledger()
    @Published var showLoadingIndicator = true
    @Published var loadingMessage: String? = "Organizing imports"
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published var showDuplicateSheet = false
    @Published var duplicate: (ImportedTransaction, String)?
    @Published var showInputRequestSheet = false
    @Published var input: (String, String, ImporterInputRequestType)? // swiftlint:disable:this large_tuple
    @Published var showDataEntrySheet = false
    @Published var transactionToImport: ImportedTransaction?

    private var currentImporter: SwiftBeanCountImporter.Importer!
    private var importers = [SwiftBeanCountImporter.Importer]()
    private var importPhase: ImportPhase = .setupImporters

#if canImport(AppKit)
    private var window: NSWindow?
#endif

    private var transaction: ImportedTransaction?
    private var inputRequestCompletion: ((String) -> Bool)?
    private var errorAlertCompletion: (() -> Void)?
    private let keychain = SimpleKeychain(accessibility: .whenUnlocked)

    private var errors = [String]()

    func startImporting(_ imports: [ImportType], from ledgerManager: LedgerManager) async {
        let ledger = try? await ledgerManager.getLedgerContent()
        importers = imports.compactMap {
            switch $0 {
            case let .csv(fileURL):
                if let importer = ImporterFactory.new(ledger: ledger, url: fileURL) {
                    return importer
                }
                errors.append("Unable to find importer for: \(fileURL)")
            case let .text(transaction, balance):
                if let importer = ImporterFactory.new(ledger: ledger, transaction: transaction, balance: balance) {
                    return importer
                }
                errors.append("Unable to find importer for text: \(transaction) \(balance)")
            case let .download(name):
                if let importer = ImporterFactory.new(ledger: ledger, name: name) {
                    return importer
                }
                errors.append("Unable to find importer for download: \(name)")
            }
            return nil
        }
        await continueImport()
    }

    func dismissError() {
        if let completion = errorAlertCompletion { // importer error
            errorAlertCompletion = nil
            completion()
        } else { // our own error
            Task {
                await continueImport()
            }
        }
    }

    func skipDuplicateImport() {
        Task { @MainActor in
            duplicate = nil
            await continueImport()
        }
    }

    func importDuplicate() {
        let transaction = duplicate!.0
        Task { @MainActor in
            duplicate = nil
            showDataEntryView(for: transaction)
        }
    }

    func input(_ result: String) {
        Task {
            Task { @MainActor in
                showInputRequestSheet = false
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            if !inputRequestCompletion!(result) {
                Task { // re-request in case of invalid input
                    await showInputRequestSheet(inputName: input!.1, inputType: input!.2)
                }
            } else {
                Task { @MainActor in
                    input = nil
                }
            }
        }
    }

    func cancelInput() {
        Task { @MainActor in
            showInputRequestSheet = false
        }
        Task {
            // skip current importer without the required input
            await nextImporter()
        }
    }

    @MainActor
    func importTransaction(_ transaction: Transaction) {
        showDataEntrySheet = false
        transactionToImport = nil
        resultLedger.add(transaction)
        Task {
            await nextTransaction()
        }
    }

    @MainActor
    func skipTransaction() {
        showDataEntrySheet = false
        transactionToImport = nil
        Task {
            await nextTransaction()
        }
    }

    @MainActor
    func skipImporter() {
        showDataEntrySheet = false
        transactionToImport = nil
        finishImporter()
    }

    private func continueImport() async {
        if !errors.isEmpty {
            await showErrorMessage()
        } else {
            switch importPhase {
            case .setupImporters:
                await nextImporter()
            case .importing:
                await nextTransaction()
            case .done:
                break
            }
        }
    }

    @MainActor
    private func showErrorMessage() {
        guard let message = errors.first else {
            return
        }
        errors.removeFirst()
        errorMessage = message
        showErrorAlert = true
    }

    @MainActor
    private func showLoadingIndicator(_ show: Bool, message: String? = nil) {
        showLoadingIndicator = show
        if let message {
            loadingMessage = message
        }
    }

    @MainActor
    private func showDuplicateSheet(for importedTransaction: ImportedTransaction) {
        duplicate = (importedTransaction, currentImporter.importName)
        showDuplicateSheet = true
    }

    @MainActor
    private func showInputRequestSheet(inputName: String, inputType: ImporterInputRequestType) {
        input = (currentImporter.importName, inputName, inputType)
        showInputRequestSheet = true
    }

    @MainActor
    private func showDataEntryView(for transaction: ImportedTransaction) {
        transactionToImport = transaction
        showDataEntrySheet = true
    }

    private func nextImporter() async {
        importPhase = .importing
        currentImporter = importers.popLast()
        if currentImporter != nil {
            await showLoadingIndicator(true, message: "Importing: \(self.currentImporter.importName)")
            currentImporter.delegate = self
            currentImporter.load()
            await nextTransaction()
        } else {
            importPhase = .done
            await showLoadingIndicator(false)
        }
    }

    private func nextTransaction() async {
        transaction = self.currentImporter.nextTransaction()
        if let importedTransaction = transaction {
            if importedTransaction.shouldAllowUserToEdit {
                try? await Task.sleep(for: .seconds(0.5))
                if importedTransaction.possibleDuplicate != nil {
                    await showDuplicateSheet(for: importedTransaction)
                } else {
                    await showDataEntryView(for: importedTransaction)
                }
            } else {
                await importTransaction(importedTransaction.transaction)
            }
        } else {
            await finishImporter()
        }
    }

    @MainActor
    private func finishImporter() {
        for balance in currentImporter.balancesToImport() {
            resultLedger.add(balance)
        }
        for price in currentImporter.pricesToImport() {
            try? self.resultLedger.add(price)
        }
        Task {
            await nextImporter()
        }
    }

}

extension ImportManager: ImporterDelegate {

#if canImport(AppKit)
    func view() -> NSView? {
        window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 700, height: 700), styleMask: .utilityWindow, backing: .buffered, defer: false)
        window?.contentView = NSView()
        window?.makeKeyAndOrderFront(nil)
        window?.isReleasedWhenClosed = false // fixes random crash when closing window
        return window?.contentView
    }

    func removeView() {
        window?.close()
    }
#else
    func view() -> UIView? {
        nil // TODO
    }

    func removeView() {
        // TODO
    }
#endif

    func requestInput(name: String, type: ImporterInputRequestType, completion: @escaping (String) -> Bool) {
        inputRequestCompletion = completion
        Task {
            await showInputRequestSheet(inputName: name, inputType: type)
        }
    }

    func saveCredential(_ value: String, for key: String) {
        // seems the keychain does not allow saving empty strings
        // it will not save but just keep the old value
        if value.isEmpty {
            do {
                try keychain.deleteItem(forKey: key)
            } catch {
                Logger.importer.error("Error deleting credential: \(error)")
            }
        } else {
            do {
                try keychain.set(value, forKey: key)
            } catch {
                Logger.importer.error("Error saving credential: \(error)")
            }
        }
    }

    func readCredential(_ key: String) -> String? {
        (try? keychain.string(forKey: key)) ?? ""
    }

    func error(_ error: Error, completion: @escaping () -> Void) {
        errorAlertCompletion = completion
        errors.append(error.localizedDescription)
        Task {
            await showErrorMessage()
        }
    }

}
