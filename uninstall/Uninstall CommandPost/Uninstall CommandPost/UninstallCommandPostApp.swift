//
//  UninstallCommandPostApp.swift
//  Uninstall CommandPost
//
//  Created by Chris Hocking on 20/2/2026.
//

import SwiftUI
import AppKit

@main
struct UninstallCommandPostApp: App {
    init() {
        NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 520, height: 340)
        .windowResizability(.contentSize)
    }
}
