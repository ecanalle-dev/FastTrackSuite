//
//  MainAppSettingsView.swift
//  FastTrackSuite
//
//  Created by Eric Canalle.
//

import SwiftUI
import LocalAuthentication

struct MainAppSettingsView: View {
    @State private var inputDomain = ""
    @State private var inputProject = ""
    @State private var inputEmail = ""
    @State private var inputToken = ""
    
    @State private var isUnlocked = false
    @State private var statusMessage = ""
    @State private var statusColor: Color = .green
    
    var body: some View {
        Form {
            if isUnlocked {
                Section(header: Text("ui.settings.cloud_config")) {
                    TextField("ui.settings.domain_placeholder", text: $inputDomain)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("ui.settings.project_placeholder", text: $inputProject)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("ui.settings.email_placeholder", text: $inputEmail)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("ui.settings.token_placeholder", text: $inputToken)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section {
                    Button(action: saveCredentials) {
                        Text("ui.btn.save_keychain")
                            .frame(maxWidth: .infinity, minHeight: 24)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.callout)
                        .foregroundColor(statusColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "lock.laptopcomputer")
                        .font(.system(size: 56))
                        .foregroundColor(.secondary)
                    
                    Text("ui.settings.protected_title")
                        .font(.title2)
                        .bold()
                    
                    Text("ui.settings.protected_desc")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                    
                    Button(action: authenticateUser) {
                        HStack {
                            Image(systemName: "touchid")
                            Text("ui.btn.unlock")
                        }
                        .frame(minWidth: 160, minHeight: 24)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.callout)
                            .foregroundColor(statusColor)
                            .padding(.top, 4)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 350)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = String(localized: "auth.reason_jira_access")
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        inputDomain = KeychainManager.get(key: "JIRA_DOMAIN") ?? ""
                        inputProject = KeychainManager.get(key: "JIRA_PROJECT") ?? ""
                        inputEmail = KeychainManager.get(key: "JIRA_EMAIL") ?? ""
                        inputToken = KeychainManager.get(key: "JIRA_TOKEN") ?? ""
                        
                        isUnlocked = true
                        statusMessage = ""
                    } else {
                        statusColor = .red
                        statusMessage = String(localized: "msg.auth_failed")
                    }
                }
            }
        } else {
            inputDomain = KeychainManager.get(key: "JIRA_DOMAIN") ?? ""
            inputProject = KeychainManager.get(key: "JIRA_PROJECT") ?? ""
            inputEmail = KeychainManager.get(key: "JIRA_EMAIL") ?? ""
            inputToken = KeychainManager.get(key: "JIRA_TOKEN") ?? ""
            isUnlocked = true
        }
    }
    
    private func saveCredentials() {
        KeychainManager.save(key: "JIRA_DOMAIN", value: inputDomain.trimmingCharacters(in: .whitespacesAndNewlines))
        KeychainManager.save(key: "JIRA_PROJECT", value: inputProject.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
        KeychainManager.save(key: "JIRA_EMAIL", value: inputEmail.trimmingCharacters(in: .whitespacesAndNewlines))
        KeychainManager.save(key: "JIRA_TOKEN", value: inputToken.trimmingCharacters(in: .whitespacesAndNewlines))
        
        statusColor = .green
        statusMessage = String(localized: "msg.keychain_saved")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            statusMessage = ""
        }
    }
}

#Preview {
    MainAppSettingsView()
}
