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
                    guard let ledger = self.parseLedger(url: path) else {
                        return
                    }
                    self.printLedgerStats(ledger: ledger)
                }
            }
        }
    }

    private func parseLedger(url: URL) -> Ledger? {
        do {
            let start = Date.timeIntervalSinceReferenceDate
            let ledger = try SwiftBeanCountParser.Parser.parse(contentOf: url)
            let end = Date.timeIntervalSinceReferenceDate
            print(String(format: "Parsing time: %.3f sec", end - start))
            return ledger
        } catch {
            print(error)
        }
        return nil
    }

    private func printLedgerStats(ledger: Ledger) {
        let start = Date.timeIntervalSinceReferenceDate
        let errors = ledger.errors
        let end = Date.timeIntervalSinceReferenceDate
        print(String(format: "Validation time: %.3f sec", end - start))

        for error in errors {
            print(error)
        }
        print("\(ledger.transactions.count) Transactions")
        print("\(ledger.accounts.count) Accounts")
        print("\(ledger.accounts.filter { $0.opening != nil }.count) Account openings")
        print("\(ledger.accounts.filter { $0.closing != nil }.count) Account closings")
        print("\(ledger.tags.count) Tags")
        print("\(ledger.commodities.count) Commodities")
        print("\(ledger.events.count) Events")
        print("\(ledger.custom.count) Customs")
        print("\(ledger.option.count) Options")
        print("\(ledger.plugins.count) Plugins")
        print("\(ledger.errors.count) Errors")
    }

}
