//
//  TransactionView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2020-06-16.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import SwiftBeanCountModel
import SwiftUI

struct TransactionView_Previews: PreviewProvider {

    static let transaction = SwiftBeanCountModel.Transaction(metaData: TransactionMetaData(date: Date(),
                                                                                           payee: "Payee",
                                                                                           narration: "Narration",
                                                                                           flag: .complete,
                                                                                           tags: [Tag(name: "Test Tag")]),
                                                             postings: [])
    static var previews: some View {
        List {

            TransactionView(transaction: transaction, in: Ledger())
            TransactionView(transaction: transaction, in: Ledger())
            TransactionView(transaction: transaction, in: Ledger())
        }
    }
}

struct TagView: View {

    var tag: Tag
    var fontSize: CGFloat = 12.0

    var body: some View {
        Text("#\(tag.name)")
            .font(.system(size: fontSize, weight: .regular))
            .lineLimit(1)
            .foregroundColor(.white)
            .padding(.vertical, 2)
            .padding(.horizontal, 3)
            .background(Color.green)
            .cornerRadius(5)
    }
}

enum TransactionValueType {
    case mixed
    case income
    case expense
    case invalid
}

struct TransactionView: View {

    private let transaction: SwiftBeanCountModel.Transaction
    private var transactionValueStrings: [String]
    private var amountColor: Color
    private var description: String

    var body: some View {
        ZStack(alignment: .leading) { // swiftlint:disable:this closure_body_length

            Color.grey
            HStack { // swiftlint:disable:this closure_body_length
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.lightRed, .darkRed]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    Text("Misc").foregroundColor(.white)
                }
                .frame(width: 40, height: 40, alignment: .center).padding()

                VStack(alignment: .leading) {

                    HStack {
                        if !transaction.metaData.payee.isEmpty {
                            Text(transaction.metaData.payee)
                                .bold()
                                .lineLimit(1)
                                .foregroundColor(.primary)
                        }

                        Text(description)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                    }

                    Text("Accounts")
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                        .padding(.bottom, 5)

                    HStack {
                        ForEach(transaction.metaData.tags, id: \.name) { tag in
                            TagView(tag: tag)
                        }
                    }

                }
                Spacer()
                VStack {
                    ForEach(transactionValueStrings, id: \.self) { string in
                        Text(string)
                            .foregroundColor(self.amountColor)
                            .lineLimit(1)
                    }
                }.padding()
            }

        }
        .cornerRadius(15)
        .shadow(radius: 2)
    }

    init(transaction: SwiftBeanCountModel.Transaction, in ledger: Ledger) {
        self.transaction = transaction
        description = transaction.metaData.narration

        let transactionValue = try? transaction.effect(in: ledger)
        transactionValueStrings = transactionValue?.amounts.map { currencySymbol, amount in "\(String(describing: amount)) \(currencySymbol)" } ?? []

        let types = transactionValue?.amounts.values.compactMap {
            if $0 == 0 {
                return nil
            }
            return $0 < 0 ? TransactionValueType.expense : TransactionValueType.income
        } ?? [TransactionValueType.invalid]

        if description.isEmpty && transaction.metaData.payee.isEmpty && types.isEmpty {
            description = "Internal Transfer"
        }

        let transactionType: TransactionValueType
        if types.allSatisfy({ $0 == .expense }) {
            transactionType = .income
        } else if types.allSatisfy({ $0 == .income }) {
            transactionType = .expense
        } else {
            transactionType = .mixed
        }

        switch transactionType {
        case .expense:
            amountColor = .red
        case .income:
            amountColor = .green
        default:
            amountColor = .primary
        }
    }

}
