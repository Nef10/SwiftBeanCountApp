//
//  InputRequestViewModel.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-12-12.
//

import Foundation
import SwiftBeanCountImporter

class InputRequestViewModel: ObservableObject, Identifiable {

    let id = UUID()
    let importerName: String
    let inputName: String
    let inputType: ImporterInputRequestType

    var onSubmit: ((String) -> Void)?
    var onCancel: (() -> Void)?

    init(importerName: String, inputName: String, inputType: ImporterInputRequestType) {
        self.importerName = importerName
        self.inputName = inputName
        self.inputType = inputType
    }
}
