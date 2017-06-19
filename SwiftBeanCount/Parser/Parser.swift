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

        var openTransaction : Transaction?

        for (lineNumber, line) in lines.enumerated() {

            if line.isEmpty || line[line.startIndex] == ";" {
                // Ignore empty lines and comments
                continue
            }

            // Posting
            if let transaction = openTransaction {
                if let posting = PostingParser.parseFrom(line: line, into: transaction, for: ledger) {
                    transaction.postings.append(posting)
                    continue
                } else { // No posting, need to close previous transaction
                    if transaction.postings.count > 0 {
                        ledger.transactions.append(transaction)
                        openTransaction = nil
                    } else {
                        ledger.errors.append("Invalid format in line \(lineNumber+1): previous Transaction \(transaction) without postings")
                    }
                }
            }

            // Transaction
            if let transactionMetaData = TransactionMetaDataParser.parseFrom(line: line) {
                openTransaction = Transaction(metaData: transactionMetaData)
                continue
            }

            if AccountParser.parseFrom(line: line, for: ledger) {
                continue
            }

            ledger.errors.append("Invalid format in line \(lineNumber+1): \(line)")

        }

        if let transaction = openTransaction { // Need to close last transaction
            if transaction.postings.count > 0 {
                ledger.transactions.append(transaction)
                openTransaction = nil
            } else {
                ledger.errors.append("Invalid format in line \(lines.count): previous Transaction \(transaction) without postings")
            }
        }

        return ledger
    }

}
