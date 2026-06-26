//
//  MenuBarQuickFormView.swift
//  FastTrackSuite
//
//  Created by Eric Canalle.
//

import SwiftUI

struct MenuBarQuickFormView: View {
    @State private var ticketTitle: String = ""
    @State private var ticketDescription: String = ""
    @State private var selectedType: TicketType = .incident
    @State private var selectedPriority: Priority = .medium
    
    @State private var isSending: Bool = false
    @State private var statusMessage: String = ""
    @State private var selectedAttachmentURL: URL? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.accentColor)
                Text("ui.title.new_ticket")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)
            
            TextField(text: $ticketTitle) {
                Text("ui.ticket.title_label")
            }
            .textFieldStyle(.roundedBorder)
            .disabled(isSending)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ui.ticket.type_label")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $selectedType) {
                        ForEach(TicketType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .disabled(isSending)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("ui.ticket.priority_label")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $selectedPriority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .disabled(isSending)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("ui.ticket.description_label")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $ticketDescription)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 80)
                    .border(Color.gray.opacity(0.2), width: 1)
                    .disabled(isSending)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.canChooseFiles = true
                    panel.title = "Anexo Rápido — MenuBar"
                    
                    if panel.runModal() == .OK {
                        selectedAttachmentURL = panel.url
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: selectedAttachmentURL == nil ? "paperclip" : "paperclip.badge.ellipsis")
                        Text(selectedAttachmentURL == nil ? "Anexar" : selectedAttachmentURL!.lastPathComponent)
                            .lineLimit(1)
                            .frame(maxWidth: 100, alignment: .leading)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isSending)
                
                if selectedAttachmentURL != nil {
                    Button(action: { selectedAttachmentURL = nil }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)
                }
                
                Spacer()
                
                Button(action: {
                    sendExpressTicket()
                }) {
                    HStack {
                        if isSending {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.trailing, 2)
                        }
                        Text("btn.dispatch")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(ticketTitle.isEmpty || isSending)
            }
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(statusMessage.contains("❌") ? .red : .primary)
                    .padding(.top, 2)
            }
        }
        .padding()
        .frame(width: 360)
    }
    
    private func sendExpressTicket() {
        isSending = true
        statusMessage = "🔄 Enviando..."
        
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
                    statusMessage = "✅ \(issueKey) criado!"
                    ticketTitle = ""
                    ticketDescription = ""
                    selectedAttachmentURL = nil
                case .failure(let error):
                    statusMessage = "❌ \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MenuBarQuickFormView()
}
