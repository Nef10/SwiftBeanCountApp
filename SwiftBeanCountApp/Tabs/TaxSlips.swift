//
//  Taxes.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-02-19.
//

import OSLog
import SwiftBeanCountTax
import SwiftUI

struct Slip: View {

    let slip: TaxSlip

    var body: some View {
        VStack {
            Text("**\(slip.header)**")

            let columns = Array(repeating: GridItem(.flexible(), alignment: .leading), count: slip.boxes.count + (slip.symbols.isEmpty ? 0 : 2))
            ScrollView {
                LazyVGrid(columns: columns) {
                    if !slip.symbols.isEmpty {
                        Text("**Symbol**")
                        Text("**Name**")
                    }
                    ForEach(slip.boxes, id: \.self) {
                        Text("**\($0)**")
                    }
                    ForEach(slip.rows) { row in
                        if !slip.symbols.isEmpty {
                            Text(row.symbol ?? "").lineLimit(1)
                            Text(row.name ?? "").lineLimit(1)
                        }
                        ForEach(row.values) { value in
                            Text(value.displayValue)
                        }
                    }
                    if !slip.symbols.isEmpty {
                        let row = slip.sumRow
                        Text("")
                        Text("**Totals**")
                        ForEach(row.values) { value in
                            Text("**\(value.displayValue)**")
                        }
                    }
                }
            }
        }
    }
}

struct TaxSlips: View {

    @EnvironmentObject var ledger: LedgerManager

    @State private var year: Int = Calendar.current.dateComponents([.year], from: Date()).year! - 1
    @State private var generating = false
    @State private var slips = [TaxSlip]()

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Tax Year:")
                TextField("", value: $year, format: .number.grouping(.never))
                    .fixedSize()
                    .padding(.horizontal, -5)
                Stepper("", value: $year)
                Spacer()
            }.padding(.bottom)
            if generating {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                Spacer()
            } else {
                TabView {
                    ForEach(slips, id: \.id) { slip in
                        Slip(slip: slip).tabItem { Text(slip.title) }.padding()
                    }
                }
            }
        }
        .padding()
        .onAppear {
            generateSlips()
        }
        .onChange(of: year) {
            generateSlips()
        }
        .onChange(of: ledger.loadingLedger) {
            if ledger.loadingLedger {
                generateSlips()
            }
        }
    }

    private func generateSlips() {
        generating = true
        Task.detached {
            do {
                let ledger = try await ledger.getLedgerContent()
                let slips = try await TaxCalculator.generateTaxSlips(from: ledger, for: year)
                DispatchQueue.main.async {
                    self.slips = slips
                    generating = false
                }
            } catch {
                DispatchQueue.main.async {
                    generating = false
                }
                Logger.tax.error("\(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    TaxSlips().environmentObject(LedgerManager(URL(fileURLWithPath: "/Users/User/Download/Test.beancount")))
}
