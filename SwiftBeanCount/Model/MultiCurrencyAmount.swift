//
//  MultiCurrencyAmount.swift
//  SwiftBeanCount
//
//  Created by Steffen Kötte on 2017-07-07.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation

protocol MultiCurrencyAmountRepresentable {
    var multiAccountAmount: MultiCurrencyAmount { get }
}

struct MultiCurrencyAmount {
    var amounts: [Commodity : Decimal]
    var decimalDigits: [Commodity : Int]
}

extension MultiCurrencyAmount {
    init() {
        amounts = [:]
        decimalDigits = [:]
    }
}

extension MultiCurrencyAmount : MultiCurrencyAmountRepresentable {
    var multiAccountAmount: MultiCurrencyAmount {
        return self
    }
}

extension MultiCurrencyAmount : Equatable {
    static func == (lhs: MultiCurrencyAmount, rhs: MultiCurrencyAmount) -> Bool {
        return lhs.amounts == rhs.amounts && lhs.decimalDigits == rhs.decimalDigits
    }
}

func + (left: MultiCurrencyAmountRepresentable, right: MultiCurrencyAmountRepresentable) -> MultiCurrencyAmount {
    var result = left.multiAccountAmount.amounts
    var decimalDigits = left.multiAccountAmount.decimalDigits
    for (commodity, decimal) in right.multiAccountAmount.amounts {
        result[commodity] = (result[commodity] ?? Decimal(0)) + decimal
    }
    for (commodity, digits) in right.multiAccountAmount.decimalDigits {
        decimalDigits[commodity] = max((decimalDigits[commodity] ?? 0), digits)
    }
    return MultiCurrencyAmount(amounts: result, decimalDigits: decimalDigits)
}

func += (left: inout MultiCurrencyAmount, right: MultiCurrencyAmountRepresentable) {
    // swiftlint:disable:next shorthand_operator
    left = left + right
}
