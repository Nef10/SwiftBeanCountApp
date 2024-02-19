// swiftlint:disable:this file_name
//  SwiftUIView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-02-18.
//

import SwiftBeanCountModel
import SwiftUI

struct ContentView1: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView2: View {
    @EnvironmentObject var ledger: LedgerManager
    @State private var error: Error?
    @State private var ledgerContent: [Account]? // swiftlint:disable:this discouraged_optional_collection

    var body: some View {
        VStack {
            Image(systemName: "flag.checkered")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Button {
                load()
            } label: {
                Text("Load Ledger")
            }
            if let error {
                Text("Error: \(error.localizedDescription)")
            }
            if let ledgerContent {
                Text("Accounts: \(ledgerContent.count)")
            }
        }
        .padding()
    }

    func load() {
        Task {
            do {
                ledgerContent = try await ledger.getLedgerContent().accounts
            } catch {
                self.error = error
            }
        }
    }
}
