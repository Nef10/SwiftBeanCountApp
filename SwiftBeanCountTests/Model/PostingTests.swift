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

    func testDescription() {
        let accountName = "Asset:💰"
        let amount = Amount(number: Decimal(1), commodity: Commodity(symbol: "💵"))
        let account = Account(name: accountName)
        let posting = Posting(account: account, amount: amount, transaction: transaction)

        XCTAssertEqual(String(describing: posting), "  \(accountName) \(String(describing: amount))")
    }

    let commoditySymbol = "EUR"
    let accountName = "Assets:Cash"
    let amountInteger = 1
    var amount1 : Amount?
    var account1 : Account?
    var posting1 : Posting?

    override func setUp() {
        amount1 = Amount(number: Decimal(amountInteger), commodity: Commodity(symbol: commoditySymbol))
        account1 = Account(name: accountName)
        posting1 = Posting(account: account1!, amount: amount1!, transaction: transaction)
    }

    func testEqual() {
        let posting2 = Posting(account: account1!, amount: amount1!, transaction: transaction)
        XCTAssertEqual(posting1, posting2)
    }

    func testEqualRespectsAccount() {
        let posting2 = Posting(account: Account(name: "\(accountName):💰"), amount: amount1!, transaction: transaction)
        XCTAssertNotEqual(posting1, posting2)
    }

    func testEqualRespectsAmount() {
        let posting2 = Posting(account: account1!, amount: Amount(number: Decimal(amountInteger), commodity: Commodity(symbol: "\(commoditySymbol)1")), transaction: transaction)
        XCTAssertNotEqual(posting1, posting2)
    }

}
