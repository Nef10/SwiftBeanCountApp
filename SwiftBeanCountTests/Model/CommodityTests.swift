//
//  CommodityTests.swift
//  SwiftBeanCountTests
//
//  Created by Steffen Kötte on 2017-06-11.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import XCTest
@testable import SwiftBeanCount

class CommodityTests: XCTestCase {

    func testDescription() {
        let string = "String"
        let tag = Commodity(symbol: string)
        XCTAssertEqual(String(describing: tag), string)
    }

    func testDescriptionSpecialCharacters() {
        let string = "💵"
        let tag = Commodity(symbol: string)
        XCTAssertEqual(String(describing: tag), string)
    }

    func testEqual() {
        let eur = Commodity(symbol: "EUR")
        let eur2 = Commodity(symbol: "EUR")
        let cad = Commodity(symbol: "CAD")
        XCTAssert(eur == eur)
        XCTAssert(eur == eur2)
        XCTAssertFalse(eur != eur)
        XCTAssertFalse(eur != eur2)
        XCTAssert(eur != cad)
        XCTAssert(eur2 != cad)
        XCTAssertFalse(eur == cad)
        XCTAssertFalse(eur2 == cad)
    }

    func testGreater() {
        let eur = Commodity(symbol: "EUR")
        let cad = Commodity(symbol: "CAD")

        XCTAssert(eur > cad)
        XCTAssertFalse(eur < cad)

        XCTAssertFalse(eur > eur)
        XCTAssertFalse(cad < cad)
    }

}
