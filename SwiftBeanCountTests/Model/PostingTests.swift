//
//  PostingTests.swift
//  SwiftBeanCountTests
//
//  Created by Steffen Kötte on 2017-06-14.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import XCTest
@testable import SwiftBeanCount

class PostingTests: XCTestCase {

    let transaction = Transaction(metaData: TransactionMetaData(date: Date(), payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))

    func testDescriptionInteger() {
        let accountName = "Asset:Cash"
        let commoditySymbol = "EUR"
        let amount = 123
        let account = Account(name: accountName)
        let commodity = Commodity(symbol: commoditySymbol)
        let posting = Posting(account: account, amount: Decimal(amount), commodity: commodity, transaction: transaction)

        XCTAssertEqual(String(describing: posting), "  \(accountName) \(amount).00 \(commoditySymbol)")
    }

    func testDescriptionFloat() {
        let accountName = "Asset:Cash"
        let commoditySymbol = "EUR"
        let account = Account(name: accountName)
        let commodity = Commodity(symbol: commoditySymbol)
        let posting = Posting(account: account, amount: Decimal(123.15), commodity: commodity, transaction: transaction)

        XCTAssertEqual(String(describing: posting), "  \(accountName) 123.15 \(commoditySymbol)")
    }

    func testDescriptionSpecialCharacters() {
        let accountName = "Asset:💰"
        let commoditySymbol = "💵"
        let amount = 123
        let account = Account(name: accountName)
        let commodity = Commodity(symbol: commoditySymbol)
        let posting = Posting(account: account, amount: Decimal(amount), commodity: commodity, transaction: transaction)

        XCTAssertEqual(String(describing: posting), "  \(accountName) \(amount).00 \(commoditySymbol)")
    }

    let accountName = "1"
    let amountInteger = 1
    let commoditySymbol = "EUR"
    var posting1 : Posting?

    override func setUp() {
        posting1 = Posting(account: Account(name: accountName), amount: Decimal(amountInteger), commodity: Commodity(symbol: commoditySymbol), transaction: transaction)
    }

    func testEqual() {
        let posting2 = Posting(account: Account(name: accountName), amount: Decimal(amountInteger), commodity: Commodity(symbol: commoditySymbol), transaction: transaction)
        XCTAssertEqual(posting1, posting2)
    }

    func testEqualRespectsAccount() {
        let posting2 = Posting(account: Account(name: "Asset:💰"), amount: Decimal(amountInteger), commodity: Commodity(symbol: commoditySymbol), transaction: transaction)
        XCTAssertNotEqual(posting1, posting2)
    }

    func testEqualRespectsAmount() {
        let posting2 = Posting(account: Account(name: accountName), amount: Decimal(10), commodity: Commodity(symbol: commoditySymbol), transaction: transaction)
        XCTAssertNotEqual(posting1, posting2)
    }

    func testEqualRespectsCommodity() {
        let posting2 = Posting(account: Account(name: accountName), amount: Decimal(amountInteger), commodity: Commodity(symbol: "💵"), transaction: transaction)
        XCTAssertNotEqual(posting1, posting2)
    }

}
