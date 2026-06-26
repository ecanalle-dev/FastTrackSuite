//
//  MainAppTicketFormView.swift
//  FastTrackSuite
//
//  Created by Eric Canalle.
//

import SwiftUI

struct MainAppTicketFormView: View {
    @State private var ticketTitle: String = ""
    @State private var ticketDescription: String = ""
    @State private var selectedType: TicketType = .incident
    @State private var selectedPriority: Priority = .medium
    
    @State private var isSending: Bool = false
    @State private var statusMessage: String = ""
    @State private var selectedAttachmentURL: URL? = nil
    
    var body: some View {
        Form {
            Section {
                TextField(text: $ticketTitle) {
                    Text("ui.ticket.title_label")
                }
                .textFieldStyle(.roundedBorder)
                .disabled(isSending)
                
                Picker(selection: $selectedType) {
                    ForEach(TicketType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                } label: {
                    Text("ui.ticket.type_label")
                }
                .pickerStyle(.menu)
                .disabled(isSending)
                
                Picker(selection: $selectedPriority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                } label: {
                    Text("ui.ticket.priority_label")
                }
                .pickerStyle(.segmented)
                .disabled(isSending)
            } header: {
                Text("ui.ticket.basic_info")
                    .font(.headline)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Section {
                TextEditor(text: $ticketDescription)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 120)
                    .border(Color.gray.opacity(0.2), width: 1)
                    .disabled(isSending)
            } header: {
                Text("ui.ticket.description_header")
                    .font(.headline)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Button(action: {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        panel.canChooseFiles = true
                        panel.title = "Selecionar Anexo para o Jira"
                        
                        if panel.runModal() == .OK {
                            selectedAttachmentURL = panel.url
                        }
                    }) {
                        HStack {
                            Image(systemName: selectedAttachmentURL == nil ? "paperclip" : "paperclip.badge.ellipsis")
                            Text(selectedAttachmentURL == nil ? "Anexar Arquivo" : selectedAttachmentURL!.lastPathComponent)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSending)
                    
                    // Botão de Limpar Anexo
                    if selectedAttachmentURL != nil {
                        Button(action: {
                            selectedAttachmentURL = nil
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .disabled(isSending)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        executeTicketDispatch()
                    }) {
                        HStack {
                            if isSending {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                            }
                            Text("btn.dispatch")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(ticketTitle.isEmpty || isSending)
                }
                
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.callout)
                        .foregroundColor(statusMessage.contains("❌") ? .red : .primary)
                        .padding(.top, 4)
                        .transition(.opacity)
                }
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 450)
    }
    
    private func executeTicketDispatch() {
        isSending = true
        statusMessage = "🔄 Comunicando com a API do Jira Cloud..."
        
        Task {
            let result = await JiraNetworkService.shared.sendTicket(
                title: ticketTitle,
                type: selectedType,
                priority: selectedPriority,
                details: ticketDescription,
                attachmentURL: selectedAttachmentURL
            )
            
            await MainActor.run {
                isSending = false
                switch result {
                case .success(let issueKey):
                    statusMessage = "✅ Ticket \(issueKey) criado com sucesso no seu Board!"
                    ticketTitle = ""
                    ticketDescription = ""
                    selectedAttachmentURL = nil
                case .failure(let error):
                    statusMessage = "❌ Falha na criação: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    MainAppTicketFormView()
}
