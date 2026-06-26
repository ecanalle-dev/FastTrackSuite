//
//  MainAppDashboardHomeView.swift
//  FastTrackSuite
//
//  Created by Eric Canalle.
//

import SwiftUI
import Charts

struct MainAppDashboardHomeView: View {
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var ticketCounts: [TicketType: Int] = [:]
    
    let columns = [
        GridItem(.adaptive(minimum: 140))
    ]
    
    private var totalTickets: Int {
        ticketCounts.values.reduce(0, +)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ui.dashboard.title")
                            .font(.system(.title, design: .rounded))
                            .bold()
                        
                        Text("ui.dashboard.subtitle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        refreshCounters()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isLoading ? 360 : 0))
                            .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)
                }
                
                if !errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(errorMessage)
                    }
                    .font(.callout)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Divider()
                
                if totalTickets > 0 {
                    HStack(alignment: .top, spacing: 32) {
                        
                        VStack(alignment: .center, spacing: 12) {
                            Text("Distribuição de Carga Viva")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Chart {
                                ForEach(TicketType.allCases, id: \.self) { type in
                                    let count = ticketCounts[type] ?? 0
                                    if count > 0 {
                                        SectorMark(
                                            angle: .value("Quantidade", count),
                                            innerRadius: .ratio(0.6), 
                                        )
                                        .foregroundStyle(by: .value("Tipo", type.rawValue))
                                        .cornerRadius(4)
                                    }
                                }
                            }
                            .chartForegroundStyleScale([
                                TicketType.incident.rawValue: colorForType(.incident),
                                TicketType.serviceRequest.rawValue: colorForType(.serviceRequest),
                                TicketType.task.rawValue: colorForType(.task),
                                TicketType.improvement.rawValue: colorForType(.improvement)
                            ])
                            .frame(width: 220, height: 220)
                            .overlay {
                                VStack {
                                    Text("\(totalTickets)")
                                        .font(.system(.title, design: .rounded))
                                        .bold()
                                    Text("Abertos")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Volumetria por Categoria")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(TicketType.allCases, id: \.self) { type in
                                    CompactCounterCardView(
                                        title: type.rawValue,
                                        count: ticketCounts[type] ?? 0,
                                        icon: iconForType(type),
                                        color: colorForType(type)
                                    )
                                }
                            }
                        }
                    }
                } else if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Calculando volumetria em tempo real via JQL...")
                        Spacer()
                    }
                    .padding(.vertical, 60)
                } else {
                    ContentUnavailableView(
                        "Fila Limpa!",
                        systemImage: "checkmark.circle.fill",
                        description: Text("Nenhum chamado aberto encontrado no seu board ativo.")
                    )
                    .padding(.vertical, 40)
                }
            }
            .padding()
        }
        .frame(minWidth: 650, minHeight: 450)
        .onAppear {
            refreshCounters()
        }
    }
    
    private func refreshCounters() {
        isLoading = true
        errorMessage = ""
        
        Task {
            let result = await JiraNetworkService.shared.fetchDashboardCounters()
            
            await MainActor.run {
                isLoading = false
                switch result {
                case .success(let counts):
                    self.ticketCounts = counts
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func iconForType(_ type: TicketType) -> String {
        switch type {
        case .incident: return "exclamationmark.octagon.fill"
        case .serviceRequest: return "person.fill.questionmark"
        case .task: return "checkmark.circle.fill"
        case .improvement: return "arrow.up.circle.fill"
        }
    }
    
    private func colorForType(_ type: TicketType) -> Color {
        switch type {
        case .incident: return .red
        case .serviceRequest: return .blue
        case .task: return .green
        case .improvement: return .orange
        }
    }
}

struct CompactCounterCardView: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.system(.title3, design: .rounded))
                    .bold()
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    MainAppDashboardHomeView()
}
