//
//  PostingParserTests.swift
//  SwiftBeanCountTests
//
//  Created by Steffen Kötte on 2017-06-09.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import XCTest
@testable import SwiftBeanCount

class PostingParserTests: XCTestCase {

    let transaction = Transaction(metaData: TransactionMetaData(date: Date(), payee: "Payee", narration: "Narration", flag: Flag.Complete, tags: []))

    var basicPosting : Posting?

    override func setUp() {
        basicPosting = { Posting(account: Account(name:"Assets:Checking"), amount: Amount(number: Decimal(1.23), commodity: Commodity(symbol: "EUR")), transaction: transaction) }()
    }

    let basicPostingString = "  Assets:Checking 1.23 EUR"
    let negativePostingString = "  Assets:Checking -1.23 EUR"
    let positivePostingString = "  Assets:Checking +1.23 EUR"
    let separatorPostingString = "  Assets:Checking -1,000.23 EUR"
    let whitespacePostingString = "         Assets:Checking        1.23    EUR     "
    let endOfLineCommentPostingString = " Assets:Checking 1.23 EUR    ;gfdsg f gfds   "
    let specialCharacterPostingString = "  Assets:💰 1.00 💵"

    func testBasic() {
        let posting = PostingParser.parseFrom(line: basicPostingString, into: transaction)!
        XCTAssertEqual(posting, basicPosting!)
    }

    func testNegative() {
        let posting = PostingParser.parseFrom(line: negativePostingString, into: transaction)!
        XCTAssertEqual(posting.amount, Amount(number: Decimal(-1.23), commodity: Commodity(symbol: "EUR")))
    }

    func testPositive() {
        let posting = PostingParser.parseFrom(line: positivePostingString, into: transaction)!
        XCTAssertEqual(posting, basicPosting!)
    }

    func testSeparator() {
        let posting = PostingParser.parseFrom(line: separatorPostingString, into: transaction)!
        XCTAssertEqual(posting.amount, Amount(number: Decimal(-1_000.23), commodity: Commodity(symbol: "EUR")))
    }

    func testWhitespace() {
        let posting = PostingParser.parseFrom(line: whitespacePostingString, into: transaction)!
        XCTAssertEqual(posting, basicPosting!)
    }

    func testSpecialCharacterPostingString() {
        let posting = PostingParser.parseFrom(line: specialCharacterPostingString, into: transaction)!
        XCTAssertEqual(posting.account, Account(name: "Assets:💰"))
        XCTAssertEqual(posting.amount, Amount(number: Decimal(1), commodity: Commodity(symbol: "💵")))
    }

    func testEndOfLineCommentPostingString() {
        let posting = PostingParser.parseFrom(line: endOfLineCommentPostingString, into: transaction)!
        XCTAssertEqual(posting, basicPosting!)
    }

    func testPerformance() {
        self.measure {
            for _ in 0...1000 {
                _ = PostingParser.parseFrom(line: basicPostingString, into: transaction)!
                _ = PostingParser.parseFrom(line: whitespacePostingString, into: transaction)!
                _ = PostingParser.parseFrom(line: endOfLineCommentPostingString, into: transaction)!
                _ = PostingParser.parseFrom(line: specialCharacterPostingString, into: transaction)!
            }
        }
    }

}

