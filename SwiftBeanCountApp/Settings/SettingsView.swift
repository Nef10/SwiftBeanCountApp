//
//  SettingsView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-12-20.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {

    var body: some View {
        TabView {
            SwiftUI.Tab("General", systemImage: "gear") {
                HStack {
                    VStack {
                        GeneralSettingsView()
                        Spacer()
                    }
                    Spacer()
                }.padding()
            }
            SwiftUI.Tab("Description Mapping", image: "DescriptionMapping") {
                HStack {
                    VStack {
                        SettingsTableView<DescriptionPayeeMapping>()
                        Spacer()
                    }
                    Spacer()
                }.padding()
            }
            SwiftUI.Tab("Account Mapping", image: "AccountMapping") {
                HStack {
                    VStack {
                        SettingsTableView<PayeeAccountMapping>()
                        Spacer()
                    }
                    Spacer()
                }.padding()
            }
        }
        .frame(minWidth: 900, minHeight: 500)
    }

}
