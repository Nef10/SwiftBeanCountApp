//
//  PostingParser.swift
//  SwiftBeanCount
//
//  Created by Steffen Kötte on 2017-06-08.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation

struct PostingParser {

    static private let amountGroup = "([-+]?[0-9]+(,[0-9]{3})*(.[0-9]+)?)"

    static private let regex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "^\\s+\(Parser.accountGroup)\\s+\(amountGroup)\\s+([^\\s]+)\\s*(;.*)?$", options: [])
    }()

    /// Parse a Posting from a line String
    ///
    /// - Parameter line: String of one line
    /// - Returns: a Posting or nil if the line does not contain a valid Posting
    static func parseFrom(line: String, into transaction: Transaction, for ledger: Ledger? = nil) -> Posting? {
        let postingMatches = line.matchingStrings(regex: self.regex)
        if let match = postingMatches[safe: 0] {
            let amount = self.parseAmountDecimalFrom(string: match[2])
            let account = ledger?.getAccountBy(name: match[1]) ?? Account(name: match[1])
            let commodity = ledger?.getCommodityBy(symbol: match[5]) ?? Commodity(symbol: match[5])
            return Posting(account: account, amount: Amount(number: amount, commodity: commodity), transaction: transaction)
        }
        return nil
    }

    static private func parseAmountDecimalFrom(string: String) -> Decimal {
        var amountString = string
        var sign = FloatingPointSign.plus
        while let index = amountString.index(of: ",") {
            amountString.remove(at: index)
        }
        if amountString.prefix(1) == "-" {
            sign = FloatingPointSign.minus
            amountString = String(amountString.suffix(amountString.count - 1))
        } else if amountString.prefix(1) == "+" {
            amountString = String(amountString.suffix(amountString.count - 1))
        }
        var exponent = 0
        if let range = amountString.index(of: ".") {
            let beforeDot = amountString.substring(to: range)
            let afterDot = amountString.substring(from: amountString.index(range, offsetBy: 1))
            amountString = beforeDot + afterDot
            exponent = afterDot.count
        }
        return Decimal(sign: sign, exponent: -exponent, significand: Decimal(UInt64(amountString)!))
    }

}
