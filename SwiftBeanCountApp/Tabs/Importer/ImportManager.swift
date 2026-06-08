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

class ImportManager: ObservableObject {

    private enum CredentialStorage {
        static let keychainKey = "importer-credentials"
    }

    @Published var resultLedger = Ledger()
    @Published var showLoadingIndicator = true
    @Published var loadingMessage: String? = "Organizing imports"
    @Published var showErrorAlert = false
    @Published var errorMessage = ""

    // Sheets
    @Published var duplicateVM: DuplicateViewModel?
    @Published var inputRequestVM: InputRequestViewModel?
    @Published var dataEntryVM: DataEntryViewModel?

    private var currentImporter: SwiftBeanCountImporter.Importer?
    private var importers = [SwiftBeanCountImporter.Importer]()
    private var importPhase: ImportPhase = .setupImporters

#if canImport(AppKit)
    private var window: NSWindow?
#endif

    private var transaction: ImportedTransaction?
    private var inputRequestCompletion: ((String) -> Bool)?
    private var errorAlertCompletion: (() -> Void)?
    private let credentialLock = NSLock()
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

    @MainActor
    func skipDuplicateImport() {
        duplicateVM = nil
        Task {
            await continueImport()
        }
    }

    @MainActor
    func importDuplicate() {
        guard let duplicateViewModel = duplicateVM else {
            Logger.importer.error("Duplicate view model not found when trying to import duplicate")
            return
        }
        duplicateVM = nil
        importTransaction(duplicateViewModel.importedTransaction)
    }

    func handleInputSubmit(_ result: String) {
        Task { @MainActor in
            let completion = inputRequestCompletion
            let currentInputVM = inputRequestVM
            inputRequestVM = nil

            guard let completion else {
                return
            }
            if !completion(result) {
                // re-request in case of invalid input
                if let currentInputVM {
                    presentInputRequest(importerName: currentInputVM.importerName,
                                        inputName: currentInputVM.inputName,
                                        inputType: currentInputVM.inputType)
                }
            }
        }
    }

    @MainActor
    func cancelInput() {
        inputRequestVM = nil
        Task {
            // skip current importer without the required input
            await nextImporter()
        }
    }

    @MainActor
    func importTransaction(_ transaction: Transaction) {
        dataEntryVM = nil
        resultLedger.add(transaction)
        Task {
            await nextTransaction()
        }
    }

    @MainActor
    func skipTransaction() {
        dataEntryVM = nil
        Task {
            await nextTransaction()
        }
    }

    @MainActor
    func skipImporter() {
        dataEntryVM = nil
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
            Logger.importer.error("No error message found to show")
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
    private func showDuplicateSheet(for importedTransaction: SwiftBeanCountModel.Transaction, possibleDuplicate: SwiftBeanCountModel.Transaction, importerName: String) {
        duplicateVM = DuplicateViewModel(importedTransaction: importedTransaction,
                                         possibleDuplicate: possibleDuplicate,
                                         importerName: importerName) { [weak self] in
            self?.importDuplicate()
        } onSkip: { [weak self] in
            self?.skipDuplicateImport()
        }
    }

    @MainActor
    private func presentInputRequest(importerName: String, inputName: String, inputType: ImporterInputRequestType) {
        inputRequestVM = InputRequestViewModel(importerName: importerName, inputName: inputName, inputType: inputType) { [weak self] result in
            self?.handleInputSubmit(result)
        } onCancel: { [weak self] in
            self?.cancelInput()
        }
    }

    @MainActor
    private func showDataEntryView(for transaction: ImportedTransaction) {
        dataEntryVM = DataEntryViewModel(importedTransaction: transaction) { [weak self] transaction in
            self?.importTransaction(transaction)
        } onSkip: { [weak self] in
            self?.skipTransaction()
        } onAbort: { [weak self] in
            self?.skipImporter()
        }
    }

    private func nextImporter() async {
        importPhase = .importing
        currentImporter = importers.popLast()
        if var importer = currentImporter {
            await showLoadingIndicator(true, message: "Importing: \(importer.importName)")
            importer.delegate = self
            importer.load()
            await nextTransaction()
        } else {
            importPhase = .done
            await showLoadingIndicator(false)
        }
    }

    private func nextTransaction() async {
        guard let importer = currentImporter else {
            Logger.importer.error("No current importer found when trying to get next transaction")
            return
        }
        transaction = importer.nextTransaction()
        if let importedTransaction = transaction {
            if importedTransaction.shouldAllowUserToEdit {
                if let possibleDuplicate = importedTransaction.possibleDuplicate {
                    await showDuplicateSheet(for: importedTransaction.transaction, possibleDuplicate: possibleDuplicate, importerName: importer.importName)
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
        guard let importer = currentImporter else {
            Logger.importer.error("No current importer found when trying to finish importer")
            return
        }
        for balance in importer.balancesToImport() {
            resultLedger.add(balance)
        }
        for price in importer.pricesToImport() {
            try? resultLedger.add(price)
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
        nil // iOS import not yet supported
    }

    func removeView() {
        // iOS import not yet supported
    }
#endif

    func requestInput(name: String, type: ImporterInputRequestType, completion: @escaping (String) -> Bool) {
        inputRequestCompletion = completion
        guard let importer = currentImporter else {
            Logger.importer.error("No current importer found when trying to request input")
            return
        }
        Task { @MainActor in
            presentInputRequest(importerName: importer.importName, inputName: name, inputType: type)
        }
    }

    func saveCredential(_ value: String, for key: String) {
        credentialLock.lock()
        defer { credentialLock.unlock() }

        var credentials = readStoredCredentialsLocked()

        // the keychain does not allow saving empty strings,
        // so empty values remove the stored credential instead
        if value.isEmpty {
            credentials.removeValue(forKey: key)
        } else {
            credentials[key] = value
        }
        persistStoredCredentialsLocked(credentials)
    }

    func readCredential(_ key: String) -> String? {
        credentialLock.lock()
        defer { credentialLock.unlock() }

        let credentials = readStoredCredentialsLocked()
        return credentials[key]
    }

    func error(_ error: Error, completion: @escaping () -> Void) {
        errorAlertCompletion = completion
        errors.append(error.localizedDescription)
        Task {
            await showErrorMessage()
        }
    }

    // Call only while holding credentialLock.
    private func readStoredCredentialsLocked() -> [String: String] {
        do {
            let storedCredentials = try keychain.string(forKey: CredentialStorage.keychainKey)
            guard let data = storedCredentials.data(using: .utf8) else {
                Logger.importer.error("Failed to convert credentials string to UTF-8 data")
                return [:]
            }

            do {
                return try JSONDecoder().decode([String: String].self, from: data)
            } catch {
                Logger.importer.error("Error decoding credentials from JSON: \(error)")
                return [:]
            }
        } catch {
            guard case SimpleKeychainError.itemNotFound = error else {
                Logger.importer.error("Error reading shared credentials: \(error)")
                return [:]
            }
            return [:]
        }
    }

    // Call only while holding credentialLock.
    private func persistStoredCredentialsLocked(_ credentials: [String: String]) {
        if credentials.isEmpty {
            do {
                try keychain.deleteItem(forKey: CredentialStorage.keychainKey)
            } catch {
                guard case SimpleKeychainError.itemNotFound = error else {
                    Logger.importer.error("Error deleting credentials: \(error)")
                    return
                }
                Logger.importer.debug("No shared importer credentials found to delete")
            }
        }

        do {
            let data = try JSONEncoder().encode(credentials)
            guard let storedCredentials = String(data: data, encoding: .utf8) else {
                Logger.importer.error("Failed to convert encoded credentials to UTF-8 string")
                return
            }
            try keychain.set(storedCredentials, forKey: CredentialStorage.keychainKey)
        } catch {
            Logger.importer.error("Error saving credentials: \(error)")
        }
    }
}
