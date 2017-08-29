//
//  FlagTests.swift
//  SwiftBeanCountTests
//
//  Created by Steffen Kötte on 2017-06-18.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

@testable import SwiftBeanCount
import XCTest

class FlagTests: XCTestCase {

    func testDescription() {
        let complete = Flag.complete
        XCTAssertEqual(String(describing: complete), "*")
        let incomplete = Flag.incomplete
        XCTAssertEqual(String(describing: incomplete), "!")
    }

}
