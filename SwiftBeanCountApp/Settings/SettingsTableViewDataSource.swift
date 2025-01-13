//
//  SettingsTableViewDataSource.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-12-21.
//

import SwiftBeanCountImporter
import SwiftUI

protocol SettingsTableViewDataSource: Identifiable { // swiftlint:disable:this file_types_order
    static var keyName: String { get }
    static var hasValue2: Bool { get }
    static var value1Name: String { get }
    static var value2Name: String { get }

    var id: UUID { get }
    var key: String { get }
    var value1: String { get }
    var value2: String { get }

    static func load() -> [Self]

    func setValue1(_ value: String)
    func setValue2(_ value: String)
    func delete()
}

struct DescriptionPayeeMapping: SettingsTableViewDataSource {
    static var keyName: String { "Imported Description" }
    static var hasValue2: Bool { true }
    static var value1Name: String { "Payee" }
    static var value2Name: String { "Description" }

    let id = UUID()
    let key: String
    let payee: String
    let description: String

    var value1: String { payee }
    var value2: String { description }

    static func load() -> [Self] {
        var result = [Self]()
        var descriptions = Settings.allDescriptionMappings
        for (key, payee) in Settings.allPayeeMappings {
            if let description = descriptions[key] {
                result.append(Self(key: key, payee: payee, description: description))
                descriptions.removeValue(forKey: key)
            } else {
                result.append(Self(key: key, payee: payee, description: ""))
            }
        }
        for (key, description) in descriptions {
            result.append(Self(key: key, payee: "", description: description))
        }
        return result
    }

    func setValue1(_ value: String) {
        Settings.setPayeeMapping(key: key, payee: value)
    }

    func setValue2(_ value: String) {
        Settings.setDescriptionMapping(key: key, description: value)
    }

    func delete() {
        Settings.setDescriptionMapping(key: key, description: nil)
        Settings.setPayeeMapping(key: key, payee: nil)
    }
}

struct PayeeAccountMapping: SettingsTableViewDataSource {
    static var keyName: String { "Payee" }
    static var hasValue2: Bool { false }
    static var value1Name: String { "Account" }
    static var value2Name: String { "" }

    let id = UUID()
    let key: String
    let account: String

    var value1: String { account }
    var value2: String { "" }

    static func load() -> [Self] {
        Settings.allAccountMappings.map { Self(key: $0.key, account: $0.value) }
    }

    func setValue1(_ value: String) {
        Settings.setAccountMapping(key: key, account: value)
    }

    func setValue2(_: String) {
        // empty
    }

    func delete() {
        Settings.setAccountMapping(key: key, account: nil)
    }
}
