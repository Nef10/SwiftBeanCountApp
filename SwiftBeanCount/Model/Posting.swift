//
//  Posting.swift
//  SwiftBeanCount
//
//  Created by Steffen Kötte on 2017-06-07.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation

struct Posting {

    let account : Account
    let amount : Decimal
    let commodity : Commodity
    unowned let transaction : Transaction

}

extension Posting : CustomStringConvertible {

    var description: String { return "  \(account.name) \(self.amountString) \(commodity)" }

    private var amountString: String { return type(of: self).numberFormatter.string(from:amount as NSDecimalNumber)! }

    static private let numberFormatter: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.numberStyle = .decimal
        _formatter.alwaysShowsDecimalSeparator = true
        _formatter.minimumFractionDigits = 2
        return _formatter
    }()

}

extension Posting : Equatable {
    static func ==(lhs: Posting, rhs: Posting) -> Bool {
        return lhs.account == rhs.account && lhs.amount == rhs.amount && lhs.commodity == rhs.commodity
    }
}
