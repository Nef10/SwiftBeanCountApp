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
        ]
#endif
        return tabs
    }

    var body: some Scene {
        let content = LedgerSelectionWrapperView(tabs)

#if os(macOS)
        // To only allow one window
        Window("SwiftBeanCountApp", id: "main") { content }.handlesExternalEvents(matching: ["*"])
#else
        WindowGroup { content }
#endif
    }
}
