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

    override func viewDidLoad() {
        super.viewDidLoad()

        if let dir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let path = dir.appendingPathComponent("Steffen.beancount")
            do {
                let start = Date.timeIntervalSinceReferenceDate
                let ledger = try Parser.parse(contentOf: path)
                let end = Date.timeIntervalSinceReferenceDate
                for error in ledger.errors {
                    print(error)
                }
                for commodity in ledger.commodities {
                    print(String(describing: commodity))
                }
                print(String(format: "Parsing time: %.3f sec", end - start))
                print("\(ledger.transactions.count) Transactions")
                print("\(ledger.accounts.count) Accounts")
                print("\(ledger.accounts.filter { $0.opening != nil }.count) Account openings")
                print("\(ledger.accounts.filter { $0.closing != nil }.count) Account closings")
                print("\(ledger.tags.count) Tags")
                print("\(ledger.commodities.count) Commodities")
                print("\(ledger.errors.count) Errors")

                print(String(describing: Array(Set(ledger.transactions.map { $0.metaData.payee })).filter { !$0.isEmpty }.sorted { $0.lowercased() < $1.lowercased() }))
            } catch let error {
                print(error)
            }
        }

    }

}
