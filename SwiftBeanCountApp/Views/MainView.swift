//
//  MainView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2020-06-01.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import SwiftBeanCountModel
import SwiftUI

struct MainView: View {

    @State private var ledger: Ledger?
    @State private var displayOpenView = false

    var body: some View {
        VStack {
            if ledger != nil {
                LedgerView(ledger!)
            } else {
                Text("No ledger loaded.")
                Button(action: {
                    self.showOpenView()
                }, label: {
                    Text("Open ledger")
                })
            }
        }.onAppear {
            self.showOpenView()
        }
        .sheet(isPresented: $displayOpenView) {
            OpenLedgerView(ledger: self.$ledger) {
                self.closeOpenView()
            }
        }
        .frame(width: 500, height: 500)
    }

    private func showOpenView() {
        displayOpenView = true
    }

    private func closeOpenView() {
        displayOpenView = false
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
