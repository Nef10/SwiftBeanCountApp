//
//  ViewController.swift
//  SwiftBeanCount
//
//  Created by Steffen Kötte on 2017-06-07.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Cocoa
import SwiftBeanCountModel
import SwiftBeanCountParser

class ViewController: NSViewController {

    override func viewDidAppear() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["beancount"]
        openPanel.begin { response in
            if response == .OK {
                if let path = openPanel.url {
                    do {
                        let start = Date.timeIntervalSinceReferenceDate
                        let ledger = try SwiftBeanCountParser.Parser.parse(contentOf: path)
                        let end = Date.timeIntervalSinceReferenceDate
                        for error in ledger.errors {
                            print(error)
                        }
                        print(String(format: "Parsing time: %.3f sec", end - start))
                        print("\(ledger.transactions.count) Transactions")
                        print("\(ledger.accounts.count) Accounts")
                        print("\(ledger.accounts.filter { $0.opening != nil }.count) Account openings")
                        print("\(ledger.accounts.filter { $0.closing != nil }.count) Account closings")
                        print("\(ledger.tags.count) Tags")
                        print("\(ledger.commodities.count) Commodities")
                        print("\(ledger.errors.count) Errors")
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }

}
