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
    let amount : Amount
    unowned let transaction : Transaction

}

extension Posting : CustomStringConvertible {
    var description: String { return "  \(account.name) \(String(describing: amount))" }
}

extension Posting : Equatable {
    static func ==(lhs: Posting, rhs: Posting) -> Bool {
        return lhs.account == rhs.account && lhs.amount == rhs.amount
    }
}
