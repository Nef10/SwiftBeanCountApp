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

    var transaction1WithoutPosting : Transaction?
    var transaction2WithoutPosting : Transaction?
    var transaction1WithPosting1 : Transaction?
    var transaction3WithPosting1 : Transaction?
    var transaction1WithPosting1And2 : Transaction?
    var transaction2WithPosting1And2 : Transaction?

    override func setUp() {
        let transactionMetaData1 = TransactionMetaData(date: Date(timeIntervalSince1970: 1496905200), payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: [])
        let transactionMetaData2 = TransactionMetaData(date: Date(timeIntervalSince1970: 1496905200), payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: [])
        let transactionMetaData3 = TransactionMetaData(date: Date(timeIntervalSince1970: 1496905200), payee: "Payee", narration: "Narration", flag: Flag.Incomplete, tags: [])

        transaction1WithoutPosting = Transaction(metaData: transactionMetaData1)

        transaction2WithoutPosting = Transaction(metaData: transactionMetaData2)

        transaction1WithPosting1 = Transaction(metaData: transactionMetaData1)
        let transaction1Posting1 = Posting(account: Account(name: "Assets:Cash"), amount: Decimal(10), commodity: Commodity(symbol: "EUR"), transaction: transaction1WithPosting1!)
        transaction1WithPosting1?.postings.append(transaction1Posting1)

        transaction3WithPosting1 = Transaction(metaData: transactionMetaData3)
        let transaction3Posting1 = Posting(account: Account(name: "Assets:Cash"), amount: Decimal(10), commodity: Commodity(symbol: "EUR"), transaction: transaction3WithPosting1!)
        transaction3WithPosting1?.postings.append(transaction3Posting1)

        transaction1WithPosting1And2 = Transaction(metaData: transactionMetaData1)
        let transaction1_12Posting1 = Posting(account: Account(name: "Assets:Cash"), amount: Decimal(10), commodity: Commodity(symbol: "EUR"), transaction: transaction1WithPosting1And2!)
        let transaction1_12Posting2 = Posting(account: Account(name: "Assets:Checking"), amount: Decimal(1), commodity: Commodity(symbol: "CAD"), transaction: transaction1WithPosting1And2!)
        transaction1WithPosting1And2?.postings.append(transaction1_12Posting1)
        transaction1WithPosting1And2?.postings.append(transaction1_12Posting2)

        transaction2WithPosting1And2 = Transaction(metaData: transactionMetaData1)
        let transaction2_12Posting1 = Posting(account: Account(name: "Assets:Cash"), amount: Decimal(10), commodity: Commodity(symbol: "EUR"), transaction: transaction2WithPosting1And2!)
        let transaction2_12Posting2 = Posting(account: Account(name: "Assets:Checking"), amount: Decimal(1), commodity: Commodity(symbol: "CAD"), transaction: transaction2WithPosting1And2!)
        transaction2WithPosting1And2?.postings.append(transaction2_12Posting1)
        transaction2WithPosting1And2?.postings.append(transaction2_12Posting2)

    }

    func testDescriptionWithoutPosting() {
        XCTAssertEqual(String(describing: transaction1WithoutPosting!), String(describing: transaction1WithoutPosting!.metaData))
    }

    func testDescriptionWithPostings() {
        XCTAssertEqual(String(describing: transaction1WithPosting1And2!), String(describing: transaction1WithPosting1And2!.metaData) + "\n" + String(describing: transaction1WithPosting1And2!.postings[0]) + "\n" + String(describing: transaction1WithPosting1And2!.postings[1]))
    }

    func testEqual() {
        XCTAssertEqual(transaction1WithoutPosting, transaction2WithoutPosting)
    }

    func testEqualWithPostings() {
        XCTAssertEqual(transaction1WithPosting1And2, transaction2WithPosting1And2)
    }

    func testEqualRespectsPostings() {
        XCTAssertNotEqual(transaction1WithPosting1, transaction1WithPosting1And2)
    }

    func testEqualRespectsTransactionMetaData() {
        XCTAssertNotEqual(transaction1WithPosting1, transaction3WithPosting1)
    }

}
