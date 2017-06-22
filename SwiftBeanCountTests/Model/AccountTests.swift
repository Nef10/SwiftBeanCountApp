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

    let date_2017_06_08 = Date(timeIntervalSince1970: 1496905200)
    let date_2017_06_09 = Date(timeIntervalSince1970: 1496991600)
    let date_2017_06_10 = Date(timeIntervalSince1970: 1497078000)

    let amount = Amount(number: Decimal(1), commodity: Commodity(symbol: "EUR"))

    func testDescription() {
        let name = "Assets:Cash"
        let accout = Account(name: name)
        XCTAssertEqual(String(describing: accout), "")
        accout.opening = date_2017_06_08
        XCTAssertEqual(String(describing: accout), "2017-06-08 open \(name)")
        let symbol = "EUR"
        accout.commodity = Commodity(symbol: symbol)
        XCTAssertEqual(String(describing: accout), "2017-06-08 open \(name) \(symbol)")
        accout.closing = date_2017_06_09
        XCTAssertEqual(String(describing: accout), "2017-06-08 open \(name) \(symbol)\n2017-06-09 close \(name)")
    }

    func testDescriptionSpecialCharacters() {
        let name = "Assets:💰"
        let accout = Account(name: name)
        XCTAssertEqual(String(describing: accout), "")
        accout.opening = date_2017_06_08
        XCTAssertEqual(String(describing: accout), "2017-06-08 open \(name)")
        let symbol = "💵"
        accout.commodity = Commodity(symbol: symbol)
        XCTAssertEqual(String(describing: accout), "2017-06-08 open \(name) \(symbol)")
        accout.closing = date_2017_06_09
        XCTAssertEqual(String(describing: accout), "2017-06-08 open \(name) \(symbol)\n2017-06-09 close \(name)")
    }

    func testIsPostingValid_NotOpenPast() {
        let account = Account(name: "name")
        let transaction = Transaction(metaData: TransactionMetaData(date: Date(timeIntervalSince1970: 0), payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))
        let posting = Posting(account: account, amount: Amount(number: Decimal(1), commodity: Commodity(symbol: "EUR")), transaction: transaction)
        XCTAssertFalse(account.isPostingValid(posting))
    }

    func testIsPostingValid_NotOpenPresent() {
        let account = Account(name: "name")
        let transaction = Transaction(metaData: TransactionMetaData(date: Date(), payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))
        let posting = Posting(account: account, amount: Amount(number: Decimal(1), commodity: Commodity(symbol: "EUR")), transaction: transaction)
        XCTAssertFalse(account.isPostingValid(posting))
    }

    func testIsPostingValid_BeforeOpening() {
        let account = Account(name: "name")
        account.opening = date_2017_06_09

        let transaction1 = Transaction(metaData: TransactionMetaData(date: Date(timeIntervalSince1970: 0), payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))
        let posting1 = Posting(account: account, amount: Amount(number: Decimal(1), commodity: Commodity(symbol: "EUR")), transaction: transaction1)
        XCTAssertFalse(account.isPostingValid(posting1))

        let transaction2 = Transaction(metaData: TransactionMetaData(date: date_2017_06_08, payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))
        let posting2 = Posting(account: account, amount: Amount(number: Decimal(1), commodity: Commodity(symbol: "EUR")), transaction: transaction2)
        XCTAssertFalse(account.isPostingValid(posting2))
    }

    func testIsPostingValid_AfterOpening() {
        let account = Account(name: "name")
        account.opening = date_2017_06_09

        let transaction1 = Transaction(metaData: TransactionMetaData(date: date_2017_06_09, payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))
        let posting1 = Posting(account: account, amount: amount, transaction: transaction1)
        XCTAssert(account.isPostingValid(posting1))

        let transaction2 = Transaction(metaData: TransactionMetaData(date: Date(), payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))
        let posting2 = Posting(account: account, amount: amount, transaction: transaction2)
        XCTAssert(account.isPostingValid(posting2))
    }

    func testIsPostingValid_BeforeClosing() {
        let account = Account(name: "name")
        account.opening = date_2017_06_09
        account.closing = date_2017_06_09
        let transaction = Transaction(metaData: TransactionMetaData(date: date_2017_06_09, payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))
        let posting = Posting(account: account, amount: amount, transaction: transaction)
        XCTAssert(account.isPostingValid(posting))
    }

    func testIsPostingValid_AfterClosing() {
        let account = Account(name: "name")
        account.opening = date_2017_06_09
        account.closing = date_2017_06_09
        let transaction = Transaction(metaData: TransactionMetaData(date: date_2017_06_10, payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))
        let posting = Posting(account: account, amount: amount, transaction: transaction)
        XCTAssertFalse(account.isPostingValid(posting))
    }

    func testIsPostingValid_WithoutCommodity() {
        let account = Account(name: "name")
        account.opening = date_2017_06_08

        let transaction1 = Transaction(metaData: TransactionMetaData(date: date_2017_06_09, payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))
        let posting1 = Posting(account: account, amount: amount, transaction: transaction1)
        XCTAssert(account.isPostingValid(posting1))

        let transaction2 = Transaction(metaData: TransactionMetaData(date: date_2017_06_09, payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))
        let posting2 = Posting(account: account, amount: amount, transaction: transaction2)
        XCTAssert(account.isPostingValid(posting2))
    }

    func testIsPostingValid_CorrectCommodity() {
        let account = Account(name: "name")
        account.commodity = amount.commodity
        account.opening = date_2017_06_08
        let transaction = Transaction(metaData: TransactionMetaData(date: date_2017_06_09, payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))
        let posting = Posting(account: account, amount: amount, transaction: transaction)
        XCTAssert(account.isPostingValid(posting))
    }

    func testIsPostingValid_WrongCommodity() {
        let account = Account(name: "name")
        account.commodity = Commodity(symbol: "\(amount.commodity.symbol)1")
        account.opening = date_2017_06_08
        let transaction = Transaction(metaData: TransactionMetaData(date: date_2017_06_09, payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))
        let posting = Posting(account: account, amount: amount, transaction: transaction)
        XCTAssertFalse(account.isPostingValid(posting))
    }

    func testEqual() {
        let name1 = "Asset:Cash"
        let name2 = "Asset:💰"
        let commodity1 = Commodity(symbol: "EUR")
        let commodity2 = Commodity(symbol: "💵")
        let date1 = date_2017_06_08
        let date2 = date_2017_06_09

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
