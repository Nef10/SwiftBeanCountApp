//
//  TransactionsView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2020-06-01.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import SwiftBeanCountModel
import SwiftUI

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        let transaction = SwiftBeanCountModel.Transaction(metaData: TransactionMetaData(date: Date(),
                                                                                               payee: "Payee",
                                                                                               narration: "Narration",
                                                                                               flag: .complete,
                                                                                               tags: [Tag(name: "Test Tag")]),
                                                                 postings: [])
        let ledger = Ledger()
        ledger.add(transaction)
        return TransactionsView(ledger)
            
    }
}

struct TransactionsView: View {

    private let ledger: Ledger
    private let transactions: [SwiftBeanCountModel.Transaction]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(transactions, id: \.self) { transaction in
                        TransactionView(transaction: transaction, in: self.ledger)
                    }
                }
            }
        }
        .padding(.all)
    }

    init(_ ledger: Ledger) {
        self.ledger = ledger
        transactions = ledger.transactions.suffix(100)

    }
}

extension Color {

    static var flatDarkBackground: Color {
        Color(decimalRed: 36, green: 36, blue: 36)
    }

    static var flatDarkCardBackground: Color {
        Color(decimalRed: 46, green: 46, blue: 46)
    }

    static var lightRed: Color {
        Color(decimalRed: 217, green: 70, blue: 113)
    }

    static var grey: Color {
        Color(decimalRed: 241, green: 241, blue: 246)
    }

    static var darkRed: Color {
        Color(decimalRed: 206, green: 57, blue: 76)
    }

    init(decimalRed red: Double, green: Double, blue: Double) {
        self.init(red: red / 255, green: green / 255, blue: blue / 255)
    }
}
