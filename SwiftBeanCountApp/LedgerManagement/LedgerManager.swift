//
//  LedgerManager.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-02-18.
//

import CryptoKit
import Foundation
import OSLog
import SwiftBeanCountModel
import SwiftBeanCountParser

enum LedgerManagerError: Error {
    case noLedgerSpecified
    case noTask
    case noAccess
}

class LedgerManager: ObservableObject {

    @Published var url: URL? {
        didSet {
            if oldValue != url {
                task?.cancel()
                loadLedger()
            }
        }
    }
    @Published var displayLedgerSelector = false
    @Published var waitingForLedgerLoad = false
    @Published private(set) var loadingLedger = false

    private var ledgerLoaded = false
    private var task: Task<(SHA256.Digest, Ledger), Error>?

    // paramters only used for previews
    init(_ ledgerURL: URL? = nil, waitingForLedgerLoad: Bool = false) {
        self.url = ledgerURL
        self.waitingForLedgerLoad = waitingForLedgerLoad
    }

    /// Re-reads the ledger file from disk and checks if the hash
    /// changed. If so it will parse again, otherwise it won't.
    /// If the loading is stil ongoing, it cancles and re-starts.
    public func refresh() {
        if !ledgerLoaded {
            Logger.ledger.info("Canceling running task due to refresh")
            task?.cancel()
            loadLedger()
        } else if let task {
            Task.detached(priority: .background) {
                do {
                    let (hash, _) = try await task.value
                    let (newHash, _) = try self.getHashAndText()
                    if hash != newHash {
                        Logger.ledger.info("Found file change during refresh")
                        self.loadLedger()
                    } else {
                        Logger.ledger.debug("No file change found during refresh")
                    }
                } catch {
                    Logger.ledger.error("\(error.localizedDescription)")
                }
            }
        } else {
            loadLedger()
        }
    }

    /// Gets the content of the currently selected ledger.
    /// It  can check the hash of the current file to the loaded
    /// one, so it does not return content older then when the
    /// method was called.
    /// If parsing needs to happen, it will set the waitingForLedgerLoad variable.
    /// - Parameter skipHashCheck:Skip loading the current file to check the hash
    /// - Returns: Ledger
    public func getLedgerContent(skipHashCheck: Bool = false) async throws -> Ledger {
        guard url != nil else {
            throw LedgerManagerError.noLedgerSpecified
        }
        guard let task else {
            throw LedgerManagerError.noTask
        }
        if !ledgerLoaded || skipHashCheck {
            DispatchQueue.main.async {
                self.waitingForLedgerLoad = true
            }
        }
        defer {
            DispatchQueue.main.async {
                self.waitingForLedgerLoad = false
            }
        }
        let (hash, ledger) = try await task.value
        if skipHashCheck {
            return ledger
        }
        let (newHash, _) = try getHashAndText()
        if hash != newHash {
            Logger.ledger.info("File changed")
            loadLedger()
            return try await getLedgerContent(skipHashCheck: true)
        }
        return ledger
    }

    @discardableResult
    private func loadLedger() -> Task<(SHA256.Digest, Ledger), Error>? {
        task?.cancel()
        DispatchQueue.main.async {
            self.ledgerLoaded = false
        }
        guard url != nil else {
            return nil
        }
        DispatchQueue.main.async {
            self.loadingLedger = true
        }
        task = Task.detached(priority: .background) { () -> (SHA256.Digest, Ledger) in
            Logger.ledger.info("Start loading ledger")
            defer {
                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        self.loadingLedger = false
                    }
                }
            }
            let (hash, text) = try self.getHashAndText()
            try Task.checkCancellation()
            let ledger = Parser.parse(string: text)
            Logger.ledger.debug("Done parsing")
            try Task.checkCancellation()
            self.ledgerLoaded = true
            return (hash, ledger)
        }
        return task
    }

    private func getHashAndText() throws -> (SHA256.Digest, String) {
        guard let url else {
            throw LedgerManagerError.noLedgerSpecified
        }
        let gotAccess = url.startAccessingSecurityScopedResource()
        if !gotAccess {
            throw LedgerManagerError.noAccess
        }
        let text = try String(contentsOf: url)
        url.stopAccessingSecurityScopedResource()
        let data = Data(text.utf8)
        let hash = SHA256.hash(data: data)
        return (hash, text)
    }

}
