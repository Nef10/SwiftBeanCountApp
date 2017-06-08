//
//  TransactionTests.swift
//  SwiftBeanCountTests
//
//  Created by Steffen Kötte on 2017-06-18.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import XCTest
@testable import SwiftBeanCount

class TransactionTests: XCTestCase {

    let transactionMetaData1 = TransactionMetaData(date: Date(timeIntervalSince1970: 1496905200), payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: [])
    let transactionMetaData2 = TransactionMetaData(date: Date(timeIntervalSince1970: 1496905200), payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: [])
    let posting1 = Posting(account: Account(name: "Assets:Cash"), amount: Decimal(10), commodity: Commodity(symbol: "EUR"))
    let posting2 = Posting(account: Account(name: "Assets:Checking"), amount: Decimal(1), commodity: Commodity(symbol: "CAD"))

    func testDescriptionWithoutPosting() {
        let transaction = Transaction(metaData: transactionMetaData1, postings: [])
        XCTAssertEqual(String(describing: transaction), String(describing: transactionMetaData1))
    }

    func testDescriptionWithPostings() {
        let transaction = Transaction(metaData: transactionMetaData1, postings: [posting1, posting2])
        XCTAssertEqual(String(describing: transaction), String(describing: transactionMetaData1) + "\n" + String(describing: posting1) + "\n" + String(describing: posting2))
    }

    func testEqual() {
        let transaction1 = Transaction(metaData: transactionMetaData1, postings: [])
        let transaction2 = Transaction(metaData: transactionMetaData2, postings: [])
        XCTAssertEqual(transaction1, transaction2)
    }

    func testEqualWithPostings() {
        let transaction1 = Transaction(metaData: transactionMetaData1, postings: [posting1, posting2])
        let transaction2 = Transaction(metaData: transactionMetaData2, postings: [posting1, posting2])
        XCTAssertEqual(transaction1, transaction2)
    }

    func testEqualRespectsPostings() {
        let transaction1 = Transaction(metaData: transactionMetaData1, postings: [posting1])
        let transaction2 = Transaction(metaData: transactionMetaData2, postings: [posting1, posting2])
        XCTAssertNotEqual(transaction1, transaction2)
    }

    func testEqualRespectsTransactionMetaData() {
        let transaction1 = Transaction(metaData: transactionMetaData1, postings: [posting1])
        let transactionMetaData = TransactionMetaData(date: Date(timeIntervalSince1970: 1496905200), payee: "Payee", narration: "Narration", flag: Flag.Incomplete, tags: [])
        let transaction2 = Transaction(metaData: transactionMetaData, postings: [posting1])
        XCTAssertNotEqual(transaction1, transaction2)
    }

}
