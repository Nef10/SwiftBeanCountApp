//
//  Transaction.swift
//  SwiftBeanCount
//
//  Created by Steffen Kötte on 2017-06-07.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation

struct Transaction {

    let metaData : TransactionMetaData
    let postings : [Posting]

}

extension Transaction : CustomStringConvertible {
    var description: String {
        var string = String(describing: metaData)
        postings.forEach({ string += "\n\(String(describing: $0))" })
        return string
    }
}

extension Transaction : Equatable {
    static func ==(lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.metaData == rhs.metaData && lhs.postings == rhs.postings
    }
}
