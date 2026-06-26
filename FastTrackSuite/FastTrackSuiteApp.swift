//
//  FastTrackSuiteApp.swift
//  FastTrackSuite
//
//  Created by Eric Canalle.
//

import SwiftUI

@main
struct FastTrackSuiteApp: App {
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowResizability(.contentMinSize)
        

        MenuBarExtra {
            MenuBarQuickFormView()
        } label: {
            Image(systemName: "bolt.horizontal.circle.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
