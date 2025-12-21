//
//  ImporterDataEntryView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-12-18.
//

import SwiftBeanCountImporter
import SwiftBeanCountModel
import SwiftUI

struct ImporterDataEntryView: View {

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    private let importManager: ImportManager
    private let date: Date
    private let amount: String

    @State private var description: String = ""
    @State private var payee: String = ""
    @State private var saveDescriptionPayeeMapping = false
    @State private var tags: String = ""
    @State private var flag: String = ""
    @State private var account: String = ""
    @State private var saveAccountMapping = false
    @State private var showAccountValidationError = false
    @State private var payees = [String]()
    @State private var accounts = [String]()

    @EnvironmentObject var ledger: LedgerManager

    var body: some View {
        Form {
            TextField("Date:", text: .constant(Self.dateFormatter.string(from: date))).disabled(true)
            TextField("Amount:", text: .constant(amount)).disabled(true).padding(.bottom)

            TextField("Payee:", text: $payee)
#if os(macOS)
                .textInputSuggestions { payeeCompeltions }
#endif
            TextField("Description:", text: $description)
            Toggle(isOn: $saveDescriptionPayeeMapping) { Text("Save this description / payee mapping") }.padding(.bottom)

            TextField("Tags:", text: $tags)
            Picker("Flag:", selection: $flag) {
                Text("Complete").tag("*")
                Text("Incomplete").tag("!")
            }.padding(.bottom)
#if os(macOS)
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
#endif
            TextField("Account:", text: $account)
#if os(macOS)
                .textInputSuggestions { accountCompletions }
#endif
            Toggle(isOn: $saveAccountMapping) { Text("Save this accout for the payee") }.disabled(!saveDescriptionPayeeMapping).padding(.bottom)
            HStack {
                Spacer()
                Button("Abort Import") { importManager.skipImporter() }
                Button("Skip") { importManager.skipTransaction() }
                Button("Save") { saveTransaction() }
            }
        }
        .padding()
        .alert("Error", isPresented: $showAccountValidationError) { Button("OK") { /* nothing */ } } message: { Text("Please enter a valid account.") }
        .onChange(of: ledger.loadingLedger, initial: true) {
            Task { await calculateAccountsAndPayees() }
        }
    }

    private var payeeCompeltions: some View {
        ForEach(payees.filter { $0.lowercased().contains(payee.lowercased()) && $0.lowercased() != payee.lowercased() }, id: \.self) {
            Text($0)
#if os(macOS)
                .textInputCompletion($0)
#endif
        }
    }

    private var accountCompletions: some View {
        ForEach(AccountType.allValues(), id: \.self) { accountType in
            let accounts = accounts.filter { $0.hasPrefix(accountType.rawValue) && $0.lowercased().contains(account.lowercased()) && $0.lowercased() != account.lowercased() }
            if !accounts.isEmpty {
                Section(content: {
                    ForEach(accounts, id: \.self) {
                        Text($0)
#if os(macOS)
                            .textInputCompletion($0)
#endif
                    }
                }, header: {
                    Text(accountType.rawValue)
                })
            }
        }
    }

    init(importManager: ImportManager) {
        self.importManager = importManager

        let importedTransaction = importManager.transactionToImport!
        let transaction = importedTransaction.transaction
        let metaData = transaction.metaData
        let posting = transaction.postings.first { $0.accountName != importedTransaction.accountName }!

        date = metaData.date
        var priceString = ""
        if posting.price != nil {
            if posting.priceType == .total {
                priceString = " @@ \(String(describing: posting.totalPrice!))"
            } else {
                priceString = " @ \(String(describing: posting.price!))"
            }
        }
        amount = String(describing: posting.amount) + priceString
        _description = State(initialValue: metaData.narration)
        _payee = State(initialValue: metaData.payee)
        _flag = State(initialValue: metaData.flag == .complete ? "*" : "!")
        _account = State(initialValue: posting.accountName.fullName)
    }

    private func calculateAccountsAndPayees() async {
        guard let ledger = try? await ledger.getLedgerContent() else {
            return
        }
        payees = Array(Set(ledger.transactions.map(\.metaData.payee))).filter { !$0.isEmpty }.sorted { $0.lowercased() < $1.lowercased() }
        accounts = Array(Set(ledger.transactions.flatMap { $0.postings.map(\.accountName.fullName) })).filter { !$0.isEmpty }.sorted { $0.lowercased() < $1.lowercased() }
    }

    private func saveTransaction() {
        guard let accountName = try? AccountName(account) else {
            showAccountValidationError = true
            return
        }
        let transaction = getTransaction(in: accountName)
        if saveDescriptionPayeeMapping, let importedTransaction = importManager.transactionToImport {
            importedTransaction.saveMapped(description: transaction.metaData.narration,
                                           payee: transaction.metaData.payee,
                                           accountName: saveAccountMapping ? accountName : nil)
        }
        importManager.importTransaction(transaction)
    }

    private func getTransaction(in accountName: AccountName) -> SwiftBeanCountModel.Transaction {
        let importedTransaction = importManager.transactionToImport!
        let transaction = importedTransaction.transaction
        let posting = transaction.postings.first { $0.accountName != importedTransaction.accountName }!

        let metaData = TransactionMetaData(date: transaction.metaData.date,
                                           payee: payee,
                                           narration: description,
                                           flag: flag == "*" ? .complete : .incomplete,
                                           tags: getTags(),
                                           metaData: transaction.metaData.metaData)
        guard let newPosting = try? Posting(accountName: accountName,
                                            amount: posting.amount,
                                            price: posting.priceType == .total ? posting.totalPrice : posting.price,
                                            priceType: posting.priceType)
        else {
            fatalError("Invalid price config in posting")
        }
        var postings: [Posting] = transaction.postings.filter { $0 != posting }
        postings.append(newPosting)
        return Transaction(metaData: metaData, postings: postings)
    }

    private func getTags() -> [Tag] {
        let tagStrings = Set(tags.components(separatedBy: CharacterSet.whitespacesAndNewlines))
        var tags = [Tag]()
        for tagString in tagStrings {
            guard !tagString.isEmpty else {
                continue
            }
            var tag = tagString
            if tagString.starts(with: "#") {
                tag = String(tagString.dropFirst())
            }
            tags.append(Tag(name: tag))
        }
        return tags
    }

}
