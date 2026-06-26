//
//  MainAppJiraValidatorView.swift
//  FastTrackSuite
//
//  Created by Eric Canalle.
//

import SwiftUI

struct MainAppJiraValidatorView: View {
    @State private var searchKey: String = ""
    @State private var isLoading: Bool = false
    @State private var statusMessage: String = ""
    @State private var validatedIssueData: [String: Any]? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ui.validator.search_header")
                    .font(.title2)
                    .bold()
                
                Text("ui.validator.instruction")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                TextField(text: $searchKey) {
                    Text("ui.validator.search_placeholder")
                }
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: 300)
                .disabled(isLoading)
                
                Button(action: {
                    performValidation()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.trailing, 4)
                        }
                        Text("ui.btn.validate")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(searchKey.isEmpty || isLoading)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            if isLoading {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView("Analisando esteira de dados do Jira...")
                    Spacer()
                }
                Spacer()
            } else if let issue = validatedIssueData {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ui.validator.result_header")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if let fields = issue["fields"] as? [String: Any] {
                                DiagnosticRowView(label: "Sumário:", value: fields["summary"] as? String ?? "N/A")
                                
                                if let status = fields["status"] as? [String: Any] {
                                    DiagnosticRowView(label: "Status Atual:", value: status["name"] as? String ?? "N/A", isHighlighted: true)
                                }
                                
                                if let priority = fields["priority"] as? [String: Any] {
                                    DiagnosticRowView(label: "Prioridade:", value: priority["name"] as? String ?? "N/A")
                                }
                                
                                if let creator = fields["creator"] as? [String: Any] {
                                    DiagnosticRowView(label: "Criado por:", value: creator["displayName"] as? String ?? "N/A")
                                }
                                
                                if let attachments = fields["attachment"] as? [[String: Any]] {
                                    DiagnosticRowView(
                                        label: "Anexos:",
                                        value: attachments.isEmpty ? "⚠️ Nenhuma evidência anexada no chamado!" : "✅ \(attachments.count) arquivo(s) detectado(s).",
                                        isAlert: attachments.isEmpty
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            } else {
                Spacer()
                HStack {
                    Spacer()
                    Text(statusMessage.isEmpty ? "Insira uma chave válida (ex: SUST-1234) para rodar o pipeline." : statusMessage)
                        .foregroundColor(statusMessage.contains("❌") ? .red : .secondary)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                Spacer()
            }
        }
        .padding()
        .frame(minWidth: 550, minHeight: 450)
    }
    
    private func performValidation() {
        isLoading = true
        statusMessage = ""
        validatedIssueData = nil
        
        Task {
            let result = await JiraNetworkService.shared.fetchIssueDetails(key: searchKey)
            
            await MainActor.run {
                isLoading = false
                switch result {
                case .success(let json):
                    self.validatedIssueData = json
                case .failure(let error):
                    self.statusMessage = "❌ \(error.localizedDescription)"
                }
            }
        }
    }
}

struct DiagnosticRowView: View {
    let label: String
    let value: String
    var isHighlighted: Bool = false
    var isAlert: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .bold()
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .foregroundColor(isAlert ? .orange : (isHighlighted ? .accentColor : .primary))
                .fontWeight(isHighlighted || isAlert ? .semibold : .regular)
            
            Spacer()
        }
        .font(.system(.body, design: .rounded))
        .padding(.vertical, 2)
    }
}

#Preview {
    MainAppJiraValidatorView()
}
