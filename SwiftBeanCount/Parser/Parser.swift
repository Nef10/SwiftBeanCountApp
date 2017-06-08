//
//  Parser.swift
//  SwiftBeanCount
//
//  Created by Steffen Kötte on 2017-06-07.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation

class Parser {

    /// Parses a given file into an array of Transactions
    ///
    /// - Parameter contentOf: URL to parse Encoding has to be UTF-8
    /// - Returns: Array of parsed Transactions
    /// - Throws: Exceptions from opening the file
    static func parse(contentOf path: URL) throws -> Ledger  {
        let text = try String(contentsOf:path)
        return self.parse(string: text)
    }

    /// Parses a given String into an array of Transactions
    ///
    /// - Parameter string: String to parse
    /// - Returns: Array of parsed Transactions
    static func parse(string: String) -> Ledger {

        let ledger = Ledger()

        let lines = string.components(separatedBy: .newlines)

        var tempPostings = [Posting]()
        var tempTransactionMetaData : TransactionMetaData?

        for (lineNumber, line) in lines.enumerated() {

            if line.isEmpty || line[line.startIndex] == ";" {
                // Ignore empty lines and comments
                continue
            }

            // Posting
            if let posting = PostingParser.parseFrom(line: line, for:ledger) {
                if tempTransactionMetaData != nil {
                    tempPostings.append(posting)
                } else {
                    ledger.errors.append("Invalid format in line \(lineNumber+1): Posting \(posting) without transaction")
                }
                continue
            } else if let transactionMetaData = tempTransactionMetaData { // No posting, need to close previous transaction
                if tempPostings.count > 0 {
                    ledger.transactions.append(Transaction(metaData:transactionMetaData, postings:tempPostings))
                    tempPostings = [Posting]()
                    tempTransactionMetaData = nil
                } else {
                    ledger.errors.append("Invalid format in line \(lineNumber+1): previous Transaction \(transactionMetaData) without postings")
                }
            }

            // Transaction
            if let transactionMetaData = TransactionMetaDataParser.parseFrom(line: line) {
                tempTransactionMetaData = transactionMetaData
                continue
            }

            if AccountParser.parseFrom(line: line, for: ledger) {
                continue
            }

            ledger.errors.append("Invalid format in line \(lineNumber+1): \(line)")

        }

        if let transactionMetaData = tempTransactionMetaData { // Need to close last transaction
            if tempPostings.count > 0 {
                ledger.transactions.append(Transaction(metaData:transactionMetaData, postings:tempPostings))
                tempPostings = [Posting]()
                tempTransactionMetaData = nil
            } else {
                ledger.errors.append("Invalid format in line \(lines.count): previous Transaction \(transactionMetaData) without postings")
            }
        }

        return ledger
    }

}
