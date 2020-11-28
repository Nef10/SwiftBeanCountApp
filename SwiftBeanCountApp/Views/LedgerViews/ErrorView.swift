//
//  ErrorView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2020-06-01.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import SwiftBeanCountModel
import SwiftUI

struct ErrorView: View {

    private let ledger: Ledger

    @State private var loading = true
    @State private var errors = [String]()

    var body: some View {
        VStack {
            if loading {
                Text("Validating ledger...")
            } else if errors.isEmpty {
                Text("No errors")
            } else {
                Text("Found \(errors.count) errors in your ledger:")
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(errors, id: \.self) { error in
                            Text(error)
                        }
                    }
                }
            }
        }.onAppear {
            guard self.loading else {
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                let errors = self.ledger.errors
                DispatchQueue.main.async {
                    self.errors = errors
                    self.loading = false
                }
            }
        }
    }

    init(_ ledger: Ledger) {
        self.ledger = ledger
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(Ledger())
    }
}
