//
//  LedgerSelectionView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-02-17.
//

import OSLog
import SwiftBeanCountModel
import SwiftUI
import UniformTypeIdentifiers

/// Forces the user to select a ledger before showing the MainNavigationView
struct LedgerSelectionWrapperView: View {

    @StateObject private var ledger = LedgerManager()
    private let tabs: [Tab]

    var body: some View {
        Group {
            if ledger.url != nil {
#if !os(macOS)
                MainNavigationView(tabs)
                        .disabled(ledger.waitingForLedgerLoad)
                        .blur(radius: ledger.waitingForLedgerLoad ? 3 : 0)
                        .overlay {
                            LoadingLedgerOverlay()
                        }
#else
                MainNavigationView(tabs)
#endif
            } else {
                WelcomeView {
                    VStack {
                        Text("To get started, open a ledger.").font(.title3)
                        Button {
                            ledger.displayLedgerSelector = true
                        } label: {
                            Text("Open ledger")
                        }.padding()
                    }
                }
            }
        }
        .onOpenURL { url in
            ledger.url = url
        }
        .fileImporter(isPresented: $ledger.displayLedgerSelector,
                      allowedContentTypes: [UTType(filenameExtension: "beancount")!]) { result in
            switch result {
            case .success(let url):
                ledger.url = url
            case .failure(let error):
                Logger.ledger.error("\(error.localizedDescription)")
            }
        }
#if os(macOS)
        .sheet(isPresented: $ledger.waitingForLedgerLoad) {
            Text("Loading Ledger")
                .frame(width: 200, height: 50)
                .interactiveDismissDisabled(true)
        }
#endif
        .environmentObject(ledger)
    }

    init(_ tabs: [Tab]) {
        self.tabs = tabs
    }
}

#Preview {
    LedgerSelectionWrapperView([
        Tab(title: "Import", icon: "square.and.arrow.down", view: AnyView(Text("Import"))),
        Tab(title: "Export", icon: "square.and.arrow.up", view: AnyView(Text("Export")))
    ])
}
