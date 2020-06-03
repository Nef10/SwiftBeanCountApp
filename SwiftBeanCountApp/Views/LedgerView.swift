//
//  LedgerView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2020-06-01.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import SwiftBeanCountModel
import SwiftUI

struct LedgerView_Previews: PreviewProvider {
    static var previews: some View {
        LedgerView(Ledger())
    }
}

struct LedgerView: View {

    private let ledger: Ledger

    var body: some View {
        TabView {
            AccountsView(ledger)
            .tabItem {
                Text("Accounts")
            }
            TransactionsView(ledger)
            .tabItem {
                Text("Transactions")
            }
            ErrorView(ledger)
            .tabItem {
                Text("Errors")
            }
        }
        .padding()
    }

    init(_ ledger: Ledger) {
        self.ledger = ledger
    }
}
