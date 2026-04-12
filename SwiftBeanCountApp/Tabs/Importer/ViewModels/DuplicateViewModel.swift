//
//  DuplicateViewModel.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-12-18.
//

import Foundation
import SwiftBeanCountImporter
import SwiftBeanCountModel

class DuplicateViewModel: ObservableObject, Identifiable {

    let id = UUID()
    let importedTransaction: ImportedTransaction
    let importerName: String
    let possibleDuplicate: SwiftBeanCountModel.Transaction

    var onImport: (() -> Void)?
    var onSkip: (() -> Void)?

    init?(importedTransaction: ImportedTransaction, importerName: String) {
        guard let possibleDuplicate = importedTransaction.possibleDuplicate else {
            return nil
        }
        self.importedTransaction = importedTransaction
        self.importerName = importerName
        self.possibleDuplicate = possibleDuplicate
    }
}
