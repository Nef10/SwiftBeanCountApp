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
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
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

    var body: some Scene {
        // Register all tab views here
        let tabs = [
            Tab(title: "Import", icon: "square.and.arrow.down", view: AnyView(ContentView1())),
            Tab(title: "Export", icon: "square.and.arrow.up", view: AnyView(ContentView2()))
        ]

        let content = LedgerSelectionWrapperView(tabs)

#if os(macOS)
        // To only allow one window
        Window("SwiftBeanCountApp", id: "main") { content }.handlesExternalEvents(matching: ["*"])
#else
        WindowGroup { content }
#endif
    }
}
