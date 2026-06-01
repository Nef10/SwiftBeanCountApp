//
//  Payees.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-12-20.
//

import OSLog
import SwiftBeanCountModel
import SwiftUI

/// Displays all payees from the ledger with their transaction counts
/// and shows potential duplicate payees with confidence scores.
struct Payees: View {

    @EnvironmentObject var ledger: LedgerManager

    @State private var loading = false
    @State private var payeeCounts = [(String, Int)]()
    @State private var duplicates = [PayeeDuplicate]()
    @State private var searchText = ""

    private var filteredPayees: [(String, Int)] {
        if searchText.isEmpty {
            return payeeCounts
        }
        return payeeCounts.filter { $0.0.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        VStack(alignment: .leading) {
            if loading {
                LoadingView()
            } else {
                content
            }
        }
        .padding()
        .onAppear {
            if !loading {
                loadPayees()
            }
        }
        .onChange(of: ledger.loadingLedger) {
            if ledger.loadingLedger {
                loadPayees()
            }
        }
    }

    private var content: some View {
#if os(macOS)
        HSplitView {
            payeeListSection.padding(.trailing)
            duplicateSection.padding(.leading)
        }
#else
        VStack {
            payeeListSection
            Divider()
            duplicateSection
        }
#endif
    }

    private var payeeListSection: some View {
        VStack(alignment: .leading) {
            Text("Payees (\(payeeCounts.count))")
                .font(.headline)
            TextField("Search payees...", text: $searchText)
                .textFieldStyle(.roundedBorder)
            List(filteredPayees, id: \.0) { payee, count in
                HStack {
                    Text(payee)
                    Spacer()
                    Text("\(count)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .frame(minWidth: 200)
    }

    private var duplicateSection: some View {
        VStack(alignment: .leading) {
            Text("Potential Duplicates (\(duplicates.count))")
                .font(.headline)
                .padding(.bottom, 4)
            if duplicates.isEmpty {
                emptyDuplicatesView
            } else {
                duplicateList
            }
        }
        .frame(minWidth: 300)
    }

    private var emptyDuplicatesView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("No potential duplicates found.")
                    .foregroundColor(.secondary)
                Spacer()
            }
            Spacer()
        }
    }

    private var duplicateList: some View {
        List(duplicates) { duplicate in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(duplicate.payee1).bold()
                    Text("\(duplicate.countPayee1)")
                    Text("↔").foregroundColor(.secondary)
                    Text(duplicate.payee2).bold()
                    Text("\(duplicate.countPayee2)")
                }
                HStack {
                    Text(duplicate.reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Confidence: \(Int(duplicate.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(confidenceColor(duplicate.confidence))
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.9 {
            return .red
        }
        if confidence >= 0.7 {
            return .orange
        }
        return .yellow
    }

    private func loadPayees() {
        loading = true
        let ledgerManager = ledger

        Task {
            do {
                let (sortedCounts, foundDuplicates) = try await Task.detached(priority: .userInitiated) {
                    Logger.payees.info("Payees - Start")
                    let ledgerContent = try await ledgerManager.getLedgerContent()
                    Logger.payees.info("Payees - Got Ledger")
                    return PayeeDuplicateDetector.processPayees(from: ledgerContent)
                }.value
                Logger.payees.info("Payees - Found \(foundDuplicates.count) potential duplicates")
                payeeCounts = sortedCounts
                duplicates = foundDuplicates
                loading = false
                Logger.payees.info("Payees - Done")
            } catch {
                loading = false
                Logger.payees.error("\(error.localizedDescription)")
            }
        }
    }

}

#Preview {
    Payees().environmentObject(LedgerManager(URL(fileURLWithPath: "/Users/User/Download/Test.beancount")))
}
