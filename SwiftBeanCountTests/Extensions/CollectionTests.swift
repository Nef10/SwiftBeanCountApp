//
//  CollectionTests.swift
//  SwiftBeanCountTests
//
//  Created by Steffen Kötte on 2017-06-10.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import XCTest
@testable import SwiftBeanCount

class CollectionTests: XCTestCase {

    func testSafeArray() {
        var array = [String]()
        XCTAssertEqual(array[safe: 0], nil)
        array.append("value")
        XCTAssertEqual(array[safe: 0], "value")
        XCTAssertEqual(array[safe: 1], nil)
    }

}
