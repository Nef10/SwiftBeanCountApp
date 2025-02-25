//
//  SwiftBeanCountApp.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-02-17.
//

import SwiftUI

struct Tab: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let view: AnyView
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ _: NSApplication) -> Bool {
        true
    }
}
#endif

@main
struct SwiftBeanCountApp: App {

#if os(macOS)
    // Needed for the code above to run - close the application when the last window is closed
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
#endif

    var tabs: [Tab] { // Register all tab views here
        var tabs = [
            Tab(title: "Tax Slips", icon: "text.page", view: AnyView(TaxSlips())),
            Tab(title: "Tax Sales", icon: "banknote", view: AnyView(TaxSales())),
        ]
#if os(macOS)
        tabs += [
            Tab(title: "Statements", icon: "doc.text", view: AnyView(Statements())),
            Tab(title: "Importer", icon: "square.and.arrow.down.on.square", view: AnyView(Importer())),
        ]
#endif
#if os(iOS)
        tabs += [
            Tab(title: "Ledger", icon: "doc.fill", view: AnyView(ChangeLedgerView())),
            Tab(title: "Settings", icon: "gear", view: AnyView(SettingsView())),
        ]
#endif
        return tabs
    }

    @StateObject private var ledger = LedgerManager()

    var body: some Scene {

        let content = LedgerSelectionWrapperView(tabs).environmentObject(ledger)

#if os(macOS)
        Window("SwiftBeanCountApp", id: "main") { content }.handlesExternalEvents(matching: ["*"])
        Window("Importer Help", id: "importer-help") { ImporterHelpView() }
#else
        WindowGroup { content }
        WindowGroup("Importer Help", id: "importer-help") { ImporterHelpView() }
#endif

#if os(macOS)
       Settings {
           SettingsView()
       }
#endif
    }
}
