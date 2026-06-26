//
//  ContentView.swift
//  FastTrackSuite
//
//  Created by Eric Canalle.
//

import SwiftUI

enum SidebarSelection: Hashable {
    case dashboard
    case newTicket
    case validator
    case settings
}

struct ContentView: View {
    @State private var selectedMenu: SidebarSelection? = .dashboard
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedMenu) {
                Section(header: Text("ui.sidebar.group_title")) {
                    NavigationLink(value: SidebarSelection.dashboard) {
                        Label(String(localized: "ui.sidebar.dashboard"), systemImage: "chart.bar.xaxis")
                    }
                    
                    NavigationLink(value: SidebarSelection.newTicket) {
                        Label(String(localized: "ui.sidebar.new_ticket"), systemImage: "doc.badge.plus")
                    }
                    
                    NavigationLink(value: SidebarSelection.validator) {
                        Label(String(localized: "ui.sidebar.validator"), systemImage: "checkmark.seal.fill")
                    }
                }
                
                Section(header: Text("ui.sidebar.settings_group")) {
                    NavigationLink(value: SidebarSelection.settings) {
                        Label(String(localized: "ui.sidebar.credentials"), systemImage: "key.fill")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            
        } detail: {
            NavigationStack {
                Group {
                    switch selectedMenu {
                    case .dashboard: MainAppDashboardHomeView()
                    case .newTicket: MainAppTicketFormView()
                    case .validator: MainAppJiraValidatorView()
                    case .settings: MainAppSettingsView()
                    case .none:
                        Text("ui.sidebar.empty_selection")
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle(navigationTitle(for: selectedMenu))
            }
        }
    }
    
    private func navigationTitle(for selection: SidebarSelection?) -> String {
        switch selection {
        case .dashboard: return String(localized: "ui.title.dashboard")
        case .newTicket: return String(localized: "ui.title.new_ticket")
        case .validator: return String(localized: "ui.title.validator")
        case .settings: return String(localized: "ui.title.settings")
        case .none: return ""
        }
    }
}
