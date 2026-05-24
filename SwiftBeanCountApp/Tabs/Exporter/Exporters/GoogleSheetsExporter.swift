//
//  GoogleSheetsExporter.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2026-05-23.
//

import AuthenticationServices
import Foundation
import GoogleAuthentication
import SwiftBeanCountModel
import SwiftBeanCountSheetSync

private enum GoogleSheetsExporterError: LocalizedError {
    case missingInputHandler
    case missingSheetURL

    var errorDescription: String? {
        switch self {
        case .missingInputHandler:
            "Unable to request the required exporter input."
        case .missingSheetURL:
            "Please provide a valid Google Sheets URL."
        }
    }
}

private final class GoogleAuthContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}

final class GoogleSheetsExporter: LedgerExporter {

    static var exporterName: String { ExportType.googleSheets.displayName }

    private static var dateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    weak var delegate: LedgerExporterDelegate?

    var exportName: String { Self.exporterName }

    private let ledger: Ledger
    private let authentication = Authentication(appID: "1039239506189-ia9evaeo7ggpp4p9f8c94dqvappke54h",
                                                consumerSecret: "08duXE23dRYMpBt1BXedX2aw",
                                                scope: "https://www.googleapis.com/auth/spreadsheets.readonly",
                                                keychainService: "de.steffenkoette.SwiftBeanCountSheetSync")

    init(ledger: Ledger) {
        self.ledger = ledger
    }

    private static func format(result: SyncResult, sheetURL: String) -> String {
        let parserErrors = if result.parserErrors.isEmpty {
            "none"
        } else {
            result.parserErrors.map { "- \($0)" }.joined(separator: "\n")
        }

        let transactions = if result.transactions.isEmpty {
            "No new transactions to upload."
        } else {
            /*
            result.transactions
                .sorted { $0.metaData.date < $1.metaData.date }
                .map { sheetFormat($0, ledgerSettings: result.ledgerSettings) }
                .joined(separator: "\n\n")
             */
            result.sheetCells.map { row in row.joined(separator: "\t") }.joined(separator: "\n\n")
        }

        return """
        Exporter: Google Sheets
        Sheet URL: \(sheetURL)
        Mode: \(result.mode)

        Transactions to upload: \(result.transactions.count)

        Parser errors:
        \(parserErrors)

        Output:
        \(transactions)
        """
    }

    private static func sheetFormat(_ transaction: SwiftBeanCountModel.Transaction, ledgerSettings: LedgerSettings) -> String {
        let amount = expensePosting(transaction)?.amount.description.components(separatedBy: " ")[0] ?? "?"
        let date = Self.dateFormatter.string(from: transaction.metaData.date)
        let category = ledgerSettings.accountNameCategories[expensePosting(transaction)?.accountName.fullName ?? ""] ?? ""
        let name = ledgerSettings.name
        return "\(date)\t\(transaction.metaData.payee)\t\(category)\t\(name)\t\(amount)\t\(transaction.metaData.narration)"
    }

    private static func expensePosting(_ transaction: SwiftBeanCountModel.Transaction) -> Posting? {
        let postings = transaction.postings.filter { $0.accountName.accountType == .expense }
        if postings.count == 1 {
            return postings.first!
        }
        return nil
    }

    func export(completion: @escaping (Result<String, Error>) -> Void) {
        switch requestSheetURL() {
        case .failure(let error):
            completion(.failure(error))
        case .success(let sheetURL):
            startAuthenticatedExport(sheetURL: sheetURL, completion: completion)
        }
    }

    private func requestSheetURL() -> Result<String, Error> {
        guard let delegate else {
            return .failure(GoogleSheetsExporterError.missingInputHandler)
        }

        var sheetURL = ""
        var wasCanceled = false
        let group = DispatchGroup()
        group.enter()

        delegate.requestInput(
            name: "Google Sheets URL",
            type: .text(["https://docs.google.com/spreadsheets/d/..."])
        ) { input in
            let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedInput.isEmpty else {
                return false
            }
            sheetURL = trimmedInput
            group.leave()
            return true
        } onCancel: {
            wasCanceled = true
            group.leave()
        }

        group.wait()

        if wasCanceled {
            return .failure(ExporterWorkflowError.canceled)
        }

        guard !sheetURL.isEmpty else {
            return .failure(GoogleSheetsExporterError.missingSheetURL)
        }
        return .success(sheetURL)
    }

    private func startAuthenticatedExport(
        sheetURL: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let authentication = authentication
        let ledger = ledger
        DispatchQueue.main.async {
            authentication.authenticate(authenticationPresentationContextProvider: GoogleAuthContext()) { result in
                switch result {
                case .success:
                    Uploader(sheetURL: sheetURL, ledger: ledger).start(authentication: authentication) { syncResult in
                        completion(syncResult.map { Self.format(result: $0, sheetURL: sheetURL) })
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

}
