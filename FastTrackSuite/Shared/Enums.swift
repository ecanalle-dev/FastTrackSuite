//
//  Enums.swift
//  FastTrackSuite
//
//  Created by Eric Canalle on 26/06/26.
//

import Foundation

enum TicketType: String, CaseIterable, Identifiable, Codable {
    case serviceRequest = "Service Request"
    case incident = "Incident"
    case task = "Task"
    case improvement = "Improvement"
    
    var id: String { self.rawValue }
    
    var localizedName: String {
        switch self {
        case .serviceRequest: return String(localized: "type.service_request", defaultValue: "Service Request")
        case .incident: return String(localized: "type.incident", defaultValue: "Incident")
        case .task: return String(localized: "type.task", defaultValue: "Task")
        case .improvement: return String(localized: "type.improvement", defaultValue: "Improvement")
        }
    }
}

enum Priority: String, CaseIterable, Identifiable, Codable {
    case high = "Alta"
    case medium = "Média"
    case low = "Baixa"
    
    var id: String { self.rawValue }
    
    var localizedName: String {
        switch self {
        case .high: return String(localized: "ui.ticket.priority_high", defaultValue: "High")
        case .medium: return String(localized: "ui.ticket.priority_medium", defaultValue: "Medium")
        case .low: return String(localized: "ui.ticket.priority_low", defaultValue: "Low")
        }
    }
}
