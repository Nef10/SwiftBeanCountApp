//
//  AmountTests.swift
//  SwiftBeanCountTests
//
//  Created by Steffen Kötte on 2017-06-21.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import XCTest
@testable import SwiftBeanCount

class AmountTests: XCTestCase {

    let amount1 = Amount(number: Decimal(1), commodity: Commodity(symbol: "CAD"))

    func testEqual() {
        let amount2 = Amount(number: Decimal(1), commodity: Commodity(symbol: "CAD"))
        XCTAssertEqual(amount1, amount2)
    }

    func testEqualRespectsAmount() {
        let amount2 = Amount(number: Decimal(10), commodity: Commodity(symbol: "CAD"))
        XCTAssertNotEqual(amount1, amount2)
    }

    func testEqualRespectsCommodity() {
        let amount2 = Amount(number: Decimal(1), commodity: Commodity(symbol: "EUR"))
        XCTAssertNotEqual(amount1, amount2)
    }

    func testDescriptionInteger() {
        let amountInteger = 123
        let commodity = Commodity(symbol: "💵")
        let amount = Amount(number: Decimal(amountInteger), commodity: commodity)

        XCTAssertEqual(String(describing: amount), "\(amountInteger).00 \(String(describing: commodity))")
    }

    func testDescriptionFloat() {
        let commodity = Commodity(symbol: "💵")
        let amount = Amount(number: Decimal(125.5), commodity: commodity)

        XCTAssertEqual(String(describing: amount), "125.50 \(String(describing: commodity))")
    }

    func testDescriptionLongFloat() {
        let commodity = Commodity(symbol: "💵")
        let amount = Amount(number: Decimal(0.0009765625), commodity: commodity)

        XCTAssertEqual(String(describing: amount), "0.0009765625 \(String(describing: commodity))")
    }

}
