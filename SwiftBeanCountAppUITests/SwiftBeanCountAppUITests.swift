//
//  SwiftBeanCountAppUITests.swift
//  SwiftBeanCountAppUITests
//
//  Created by Steffen Kötte on 2020-06-01.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import XCTest

class SwiftBeanCountAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run.
    }

    func testAppLanch() throws {
        let app = XCUIApplication()
        app.launch()
    }

}
