//
//  OpenLedgerView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2020-06-01.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import SwiftBeanCountModel
import SwiftBeanCountParser
import SwiftUI

struct OpenLedgerView: View {

    private let completion: () -> Void

    @Binding private var ledger: Ledger?

    @State private var ledgerURL: URL?
    @State private var loadingLedger = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("Ledger:")
                FileSelectorView(allowedFileTypes: ["beancount"], url: $ledgerURL)
            }
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    cancel()
                }, label: {
                    Text("Cancel")
                })
                Button(action: {
                    loadLedger()
                }, label: {
                    Text("Open")
                }).disabled(ledgerURL == nil)
            }
        }.sheet(isPresented: $loadingLedger) {
            Text("Loading ledger...").frame(width: 200, height: 50)
        }
        .padding()
        .frame(width: 300, height: 125)
    }

    init(ledger: Binding<Ledger?>, completion: @escaping () -> Void) {
        self._ledger = ledger
        self.completion = completion
    }

    private func loadLedger() {
        guard let ledgerURL else {
            return
        }
        loadingLedger = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                ledger = try Parser.parse(contentOf: ledgerURL)
            } catch {
                print(error)
            }
            DispatchQueue.main.async {
                loadingLedger = false
                completion()
            }
        }
    }

    private func cancel() {
        completion()
    }
}

struct OpenLedgerView_Previews: PreviewProvider {
    static var previews: some View {
        OpenLedgerView(ledger: .constant(nil)) {
        }
    }
}
