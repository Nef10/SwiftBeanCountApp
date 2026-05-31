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
            payeeListSection
            duplicateSection
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
                .padding(.bottom, 4)
            TextField("Search payees...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.bottom, 4)
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
                    Text("↔").foregroundColor(.secondary)
                    Text(duplicate.payee2).bold()
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
        Task.detached {
            do {
                Logger.payees.info("Payees - Start")
                let ledgerContent = try await ledger.getLedgerContent()
                Logger.payees.info("Payees - Got Ledger")
                let (sortedCounts, foundDuplicates) = Self.processPayees(from: ledgerContent)
                Logger.payees.info("Payees - Found \(foundDuplicates.count) potential duplicates")
                DispatchQueue.main.async {
                    self.payeeCounts = sortedCounts
                    self.duplicates = foundDuplicates
                    loading = false
                }
                Logger.payees.info("Payees - Done")
            } catch {
                DispatchQueue.main.async {
                    loading = false
                }
                Logger.payees.error("\(error.localizedDescription)")
            }
        }
    }

    private static func processPayees(from ledger: Ledger) -> ([(String, Int)], [PayeeDuplicate]) {
        var counts = [String: Int]()
        for transaction in ledger.transactions {
            let payee = transaction.metaData.payee
            guard !payee.isEmpty else { continue }
            counts[payee, default: 0] += 1
        }
        let sortedCounts = counts.sorted { $0.key.lowercased() < $1.key.lowercased() }.map { ($0.key, $0.value) }
        let payeeNames = sortedCounts.map(\.0)
        let duplicates = PayeeDuplicateDetector.findDuplicates(in: payeeNames)
        return (sortedCounts, duplicates)
    }
}

#Preview {
    Payees().environmentObject(LedgerManager(URL(fileURLWithPath: "/Users/User/Download/Test.beancount")))
}
