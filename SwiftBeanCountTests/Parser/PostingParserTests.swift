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

    let basicPostingString = "  Assets:Checking 1.23 EUR"
    let negativePostingString = "  Assets:Checking -1.23 EUR"
    let positivePostingString = "  Assets:Checking +1.23 EUR"
    let separatorPostingString = "  Assets:Checking -1,000.23 EUR"
    let whitespacePostingString = "         Assets:Checking        1.23    EUR     "
    let endOfLineCommentPostingString = " Assets:Checking 1.23 EUR    ;gfdsg f gfds   "
    let specialCharacterPostingString = "  Assets:💰 1.00 💵"

    func testBasic() {
        let posting = PostingParser.parseFrom(line: basicPostingString)!
        XCTAssertEqual(String(describing: posting), basicPostingString)
    }

    func testNegative() {
        let posting = PostingParser.parseFrom(line: negativePostingString)!
        XCTAssertEqual(String(describing: posting), negativePostingString)
    }

    func testPositive() {
        let posting = PostingParser.parseFrom(line: positivePostingString)!
        XCTAssertEqual(String(describing: posting), basicPostingString)
    }

    func testSeparator() {
        let posting = PostingParser.parseFrom(line: separatorPostingString)!
        XCTAssertEqual(String(describing: posting), separatorPostingString)
    }

    func testWhitespace() {
        let posting = PostingParser.parseFrom(line: whitespacePostingString)!
        XCTAssertEqual(String(describing: posting), basicPostingString)
    }

    func testSpecialCharacterPostingString() {
        let posting = PostingParser.parseFrom(line: specialCharacterPostingString)!
        XCTAssertEqual(String(describing: posting), specialCharacterPostingString)
    }

    func testEndOfLineCommentPostingString() {
        let posting = PostingParser.parseFrom(line: endOfLineCommentPostingString)!
        XCTAssertEqual(String(describing: posting), basicPostingString)
    }

    func testPerformance() {
        self.measure {
            for _ in 0...1000 {
                _ = PostingParser.parseFrom(line: basicPostingString)!
                _ = PostingParser.parseFrom(line: whitespacePostingString)!
                _ = PostingParser.parseFrom(line: endOfLineCommentPostingString)!
                _ = PostingParser.parseFrom(line: specialCharacterPostingString)!
            }
        }
    }

}

