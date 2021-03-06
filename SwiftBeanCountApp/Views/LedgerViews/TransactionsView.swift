//
//  TransactionsView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2020-06-01.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import SwiftBeanCountModel
import SwiftUI

struct TransactionsView: View {

    private let ledger: Ledger

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }

    init(_ ledger: Ledger) {
        self.ledger = ledger
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView(Ledger())
    }
}
