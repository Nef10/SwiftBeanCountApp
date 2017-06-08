//
//  AccountTests.swift
//  SwiftBeanCountTests
//
//  Created by Steffen Kötte on 2017-06-11.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import XCTest
@testable import SwiftBeanCount

class AccountTests: XCTestCase {

    func testDescription() {
        let name = "Assets:Cash"
        let accout = Account(name: name)
        XCTAssertEqual(String(describing: accout), "")
        accout.opening = Date(timeIntervalSince1970: 1496905200)
        XCTAssertEqual(String(describing: accout), "2017-06-08 open \(name)")
        let symbol = "EUR"
        accout.commodity = Commodity(symbol: symbol)
        XCTAssertEqual(String(describing: accout), "2017-06-08 open \(name) \(symbol)")
        accout.closing = Date(timeIntervalSince1970: 1496991600)
        XCTAssertEqual(String(describing: accout), "2017-06-08 open \(name) \(symbol)\n2017-06-09 close \(name)")
    }

    func testDescriptionSpecialCharacters() {
        let name = "Assets:💰"
        let accout = Account(name: name)
        XCTAssertEqual(String(describing: accout), "")
        accout.opening = Date(timeIntervalSince1970: 1496905200)
        XCTAssertEqual(String(describing: accout), "2017-06-08 open \(name)")
        let symbol = "💵"
        accout.commodity = Commodity(symbol: symbol)
        XCTAssertEqual(String(describing: accout), "2017-06-08 open \(name) \(symbol)")
        accout.closing = Date(timeIntervalSince1970: 1496991600)
        XCTAssertEqual(String(describing: accout), "2017-06-08 open \(name) \(symbol)\n2017-06-09 close \(name)")
    }

    func testEqual() {
        let name1 = "Asset:Cash"
        let name2 = "Asset:💰"
        let commodity1 = Commodity(symbol: "EUR")
        let commodity2 = Commodity(symbol: "💵")
        let date1 = Date(timeIntervalSince1970: 1496905200)
        let date2 = Date(timeIntervalSince1970: 1496991600)

        let account1 = Account(name: name1)
        let account2 = Account(name: name1)
        let account3 = Account(name: name2)

        // equal
        XCTAssertEqual(account1, account2)
        // different name
        XCTAssertNotEqual(account1, account3)

        account1.commodity = commodity1
        account2.commodity = commodity1
        account1.opening = date1
        account2.opening = date1
        account1.closing = date1
        account2.closing = date1

        // equal
        XCTAssertEqual(account1, account2)
        // different commodity
        account2.commodity = commodity2
        XCTAssertNotEqual(account1, account2)
        account2.commodity = commodity1
        // different opening
        account2.opening = date2
        XCTAssertNotEqual(account1, account2)
        account2.opening = date1
        // different closing
        account2.closing = date2
        XCTAssertNotEqual(account1, account2)
        account2.closing = date1
    }

}
