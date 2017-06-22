//
//  Amount.swift
//  SwiftBeanCount
//
//  Created by Steffen Kötte on 2017-06-21.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation

struct Amount {
    let number : Decimal
    let commodity : Commodity
}

extension Amount : CustomStringConvertible {

    var description : String { return "\(amountString) \(commodity)" }

    private var amountString : String { return type(of: self).numberFormatter.string(from:number as NSDecimalNumber)! }

    static private let numberFormatter : NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.numberStyle = .decimal
        _formatter.alwaysShowsDecimalSeparator = true
        _formatter.minimumFractionDigits = 2
        _formatter.maximumFractionDigits = 100
        return _formatter
    }()

}

extension Amount : Equatable {
    static func ==(lhs: Amount, rhs: Amount) -> Bool {
        return lhs.number == rhs.number && lhs.commodity == rhs.commodity
    }
}
