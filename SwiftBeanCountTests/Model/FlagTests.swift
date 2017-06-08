//
//  FlagTests.swift
//  SwiftBeanCountTests
//
//  Created by Steffen Kötte on 2017-06-18.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import XCTest
@testable import SwiftBeanCount

class FlagTests: XCTestCase {

    func testDescription() {
        let complete = Flag.Complete
        XCTAssertEqual(String(describing: complete), "*")
        let incomplete = Flag.Incomplete
        XCTAssertEqual(String(describing: incomplete), "!")
    }

}
