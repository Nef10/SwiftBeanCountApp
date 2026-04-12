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

    @Published var resultLedger = Ledger()
    @Published var showLoadingIndicator = true
    @Published var loadingMessage: String? = "Organizing imports"
    @Published var showErrorAlert = false
    @Published var errorMessage = ""

    // Sheet items — using optional Identifiable VMs instead of bool + force-unwrapped data
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
            return
        }
        let importedTransaction = duplicateViewModel.importedTransaction
        duplicateVM = nil
        showDataEntryView(for: importedTransaction)
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

    func cancelInput() {
        Task { @MainActor in
            inputRequestVM = nil
        }
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
        guard let importer = currentImporter else {
            return
        }
        guard let duplicateViewModel = DuplicateViewModel(importedTransaction: importedTransaction,
                                                          importerName: importer.importName) else {
            return
        }
        duplicateViewModel.onImport = { [weak self] in self?.importDuplicate() }
        duplicateViewModel.onSkip = { [weak self] in self?.skipDuplicateImport() }
        duplicateVM = duplicateViewModel
    }

    @MainActor
    private func presentInputRequest(importerName: String, inputName: String, inputType: ImporterInputRequestType) {
        let inputViewModel = InputRequestViewModel(importerName: importerName, inputName: inputName, inputType: inputType)
        inputViewModel.onSubmit = { [weak self] result in self?.handleInputSubmit(result) }
        inputViewModel.onCancel = { [weak self] in self?.cancelInput() }
        inputRequestVM = inputViewModel
    }

    @MainActor
    private func showDataEntryView(for transaction: ImportedTransaction) {
        let entryViewModel = DataEntryViewModel(importedTransaction: transaction)
        entryViewModel.onImport = { [weak self] transaction in self?.importTransaction(transaction) }
        entryViewModel.onSkip = { [weak self] in self?.skipTransaction() }
        entryViewModel.onAbort = { [weak self] in self?.skipImporter() }
        dataEntryVM = entryViewModel
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
            return
        }
        transaction = importer.nextTransaction()
        if let importedTransaction = transaction {
            if importedTransaction.shouldAllowUserToEdit {
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
        guard let importer = currentImporter else {
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
            return
        }
        Task { @MainActor in
            presentInputRequest(importerName: importer.importName, inputName: name, inputType: type)
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
        try? keychain.string(forKey: key)
    }

    func error(_ error: Error, completion: @escaping () -> Void) {
        errorAlertCompletion = completion
        errors.append(error.localizedDescription)
        Task {
            await showErrorMessage()
        }
    }

}
