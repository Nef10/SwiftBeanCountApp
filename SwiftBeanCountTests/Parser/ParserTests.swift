//
//  ParserTests.swift
//  SwiftBeanCountTests
//
//  Created by Steffen Kötte on 2017-06-08.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import XCTest
@testable import SwiftBeanCount

class ParserTests: XCTestCase {

    enum TestFile : String {
        case Minimal = "Minimal"
        case PostingWithoutTransaction = "PostingWithoutTransaction"
        case TransactionWithoutPosting = "TransactionWithoutPosting"
        case Comments = "Comments"
        case CommentsEndOfLine = "CommentsEndOfLine"
        case Whitespace = "Whitespace"
        case Big = "Big"

        static let withoutError = [Minimal, Comments, CommentsEndOfLine, Whitespace, Big]

    }

    func testMinimal() {
        ensureMinimal(testFile: .Minimal)
    }

    func testWhitespace() {
        ensureMinimal(testFile: .Whitespace)
    }

    func testPostingWithoutTransaction() {
        let ledger = ensureEmpty(testFile: .PostingWithoutTransaction)
        XCTAssertEqual(ledger.errors.count, 1)
    }

    func testTransactionWithoutPosting() {
        let ledger = ensureEmpty(testFile: .TransactionWithoutPosting)
        XCTAssertEqual(ledger.errors.count, 1)
        XCTAssertEqual(ledger.errors[0], "Invalid format in line 2: previous Transaction 2017-06-08 * \"Payee\" \"Narration\" without postings")
    }

    func testComments() {
        let ledger = ensureEmpty(testFile: .Comments)
        XCTAssertEqual(ledger.errors.count, 0)
    }

    func testCommentsEndOfLine() {
        ensureMinimal(testFile: .CommentsEndOfLine)
    }

    func testRoundTrip() {
        do {
            for testFile in TestFile.withoutError {
                let ledger1 = try Parser.parse(contentOf: urlFor(testFile: testFile))
                let ledger2 = Parser.parse(string: String(describing: ledger1))
                XCTAssertEqual(ledger1, ledger2)
            }
        } catch let error {
            XCTFail(String(describing: error))
        }
    }

    func testPerformance() {
        self.measure {
            do {
                _ = try Parser.parse(contentOf: urlFor(testFile: .Big))
            } catch let error {
                XCTFail(String(describing: error))
            }
        }
    }

    //  Helper

    private func urlFor(testFile : TestFile) -> URL {
        return NSURL.fileURL(withPath: Bundle(for: type(of: self)).path(forResource: testFile.rawValue, ofType: "beancount")!)
    }

    private func ensureEmpty(testFile : TestFile) -> Ledger {
        do {
            let ledger = try Parser.parse(contentOf: urlFor(testFile: testFile))
            XCTAssertEqual(ledger.transactions.count, 0)
            return ledger
        } catch let error {
            XCTFail(String(describing: error))
        }
        return Ledger()
    }

    private func ensureMinimal(testFile : TestFile) -> Void {
        do {
            let ledger = try Parser.parse(contentOf: urlFor(testFile: testFile))
            XCTAssertEqual(ledger.transactions.count, 1)
            XCTAssertEqual(ledger.errors.count, 0)
            XCTAssertEqual(ledger.commodities.count, 1)
            XCTAssertEqual(ledger.accounts.count, 2)
            let transaction = ledger.transactions[0]
            XCTAssertEqual(transaction.postings.count, 2)
            XCTAssertEqual(transaction.metaData.payee, "Payee")
            XCTAssertEqual(transaction.metaData.narration, "Narration")
            XCTAssertEqual(transaction.metaData.date, Date(timeIntervalSince1970: 1496905200))
            let posting1 = transaction.postings.first(where: {$0.amount == Decimal(-1)})!
            XCTAssert(posting1.account === ledger.getAccountBy(name: "Equity:OpeningBalance"))
            XCTAssert(posting1.commodity === ledger.getCommodityBy(symbol: "EUR"))
            let posting2 = transaction.postings.first(where: {$0.amount == Decimal(1)})!
            XCTAssert(posting2.account === ledger.getAccountBy(name: "Assets:Checking"))
            XCTAssert(posting2.commodity === ledger.getCommodityBy(symbol: "EUR"))
        } catch let error {
            XCTFail(String(describing: error))
        }
    }

}
