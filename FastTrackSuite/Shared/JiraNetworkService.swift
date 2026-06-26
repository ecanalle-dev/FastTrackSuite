//
//  JiraNetworkService.swift
//  FastTrackSuite
//
//  Created by Eric Canalle.
//

import Foundation
import UniformTypeIdentifiers

enum JiraError: LocalizedError {
    case missingCredentials
    case invalidURL
    case badResponse(statusCode: Int)
    case attachmentUploadFailed
    
    var errorDescription: String? {
        switch self {
        case .missingCredentials: return "Configurações do Jira incompletas no Keychain."
        case .invalidURL: return "URL do subdomínio inválida."
        case .badResponse(let code): return "Erro no Jira. Status HTTP: \(code)"
        case .attachmentUploadFailed: return "Falha ao processar os dados do anexo."
        }
    }
}

class JiraNetworkService {
    static let shared = JiraNetworkService()
    private init() {}
    
    // MARK: - Mecanismo de Cache em Memória
    private var cachedCounters: [TicketType: Int]? = nil
    private var lastCacheFetchTime: Date? = nil
    private let cacheExpirationInterval: TimeInterval = 300 // 300 segundos = 5 minutos
    
    func sendTicket(title: String, type: TicketType, priority: Priority, details: String, attachmentURL: URL? = nil) async -> Result<String, Error> {
        guard let domain = KeychainManager.get(key: "JIRA_DOMAIN"),
              let project = KeychainManager.get(key: "JIRA_PROJECT"),
              let email = KeychainManager.get(key: "JIRA_EMAIL"),
              let token = KeychainManager.get(key: "JIRA_TOKEN"),
              !domain.isEmpty, !project.isEmpty, !email.isEmpty, !token.isEmpty else {
            return .failure(JiraError.missingCredentials)
        }
        
        let urlString = "https://\(domain).atlassian.net/rest/api/3/issue"
        guard let url = URL(string: urlString) else {
            return .failure(JiraError.invalidURL)
        }
        
        let loginString = "\(email):\(token)"
        guard let loginData = loginString.data(using: .utf8) else {
            return .failure(JiraError.invalidURL)
        }
        let base64LoginString = loginData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        
        let jiraPriorityName: String
        switch priority {
        case .high: jiraPriorityName = "High"
        case .medium: jiraPriorityName = "Medium"
        case .low: jiraPriorityName = "Low"
        }
        
        let payload: [String: Any] = [
            "fields": [
                "project": [
                    "key": project
                ],
                "summary": title,
                "issuetype": [
                    "name": type.rawValue
                ],
                "priority": [
                    "name": jiraPriorityName
                ],
                "description": [
                    "type": "doc",
                    "version": 1,
                    "content": [
                        [
                            "type": "paragraph",
                            "content": [
                                [
                                    "type": "text",
                                    "text": "[Aberto via FastTrack Suite — Desktop]",
                                    "marks": [["type": "em"]]
                                ]
                            ]
                        ],
                        ["type": "rule"],
                        [
                            "type": "paragraph",
                            "content": [
                                [
                                    "type": "text",
                                    "text": "📋 DETALHES DA OPERAÇÃO N3\n",
                                    "marks": [["type": "strong"]]
                                ],
                                [
                                    "type": "text",
                                    "text": "• Data de Abertura: ",
                                    "marks": [["type": "strong"]]
                                ],
                                ["type": "text", "text": "\(timestamp)\n"],
                                [
                                    "type": "text",
                                    "text": "• Tipo de Registro: ",
                                    "marks": [["type": "strong"]]
                                ],
                                ["type": "text", "text": "\(type.rawValue)\n"],
                                [
                                    "type": "text",
                                    "text": "• Prioridade Indicada: ",
                                    "marks": [["type": "strong"]]
                                ],
                                ["type": "text", "text": "\(jiraPriorityName)\n"]
                            ]
                        ],
                        ["type": "rule"],
                        [
                            "type": "paragraph",
                            "content": [
                                [
                                    "type": "text",
                                    "text": "📝 DESCRIÇÃO / JUSTIFICATIVA:\n",
                                    "marks": [["type": "strong"]]
                                ],
                                [
                                    "type": "text",
                                    "text": details.isEmpty ? "Nenhuma justificativa detalhada foi fornecida pelo analista." : details
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(JiraError.badResponse(statusCode: 0))
            }
            
            if httpResponse.statusCode == 201 {
                if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let issueKey = jsonResult["key"] as? String {
                    
                    if let fileURL = attachmentURL {
                        let attachmentResult = await uploadAttachment(to: issueKey, fileURL: fileURL, domain: domain, base64Auth: base64LoginString)
                        switch attachmentResult {
                        case .success:
                            return .success(issueKey)
                        case .failure(let error):
                            return .failure(error)
                        }
                    }
                    
                    return .success(issueKey)
                }
                return .success("Issue Criada")
            } else {
                return .failure(JiraError.badResponse(statusCode: httpResponse.statusCode))
            }
            
        } catch {
            return .failure(error)
        }
    }
    
    private func uploadAttachment(to issueKey: String, fileURL: URL, domain: String, base64Auth: String) async -> Result<Void, Error> {
        let urlString = "https://\(domain).atlassian.net/rest/api/3/issue/\(issueKey)/attachments"
        guard let url = URL(string: urlString) else { return .failure(JiraError.invalidURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        request.setValue("no-check", forHTTPHeaderField: "X-Atlassian-Token")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        do {
            let accessing = fileURL.startAccessingSecurityScopedResource()
            defer { if accessing { fileURL.stopAccessingSecurityScopedResource() } }
            
            let fileData = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            let mimeType = UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
            
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return .failure(JiraError.badResponse(statusCode: 0)) }
            
            if httpResponse.statusCode == 200 {
                return .success(())
            } else {
                return .failure(JiraError.badResponse(statusCode: httpResponse.statusCode))
            }
        } catch {
            return .failure(error)
        }
    }
    
    func fetchIssueDetails(key: String) async -> Result<[String: Any], Error> {
        guard let domain = KeychainManager.get(key: "JIRA_DOMAIN"),
              let email = KeychainManager.get(key: "JIRA_EMAIL"),
              let token = KeychainManager.get(key: "JIRA_TOKEN"),
              !domain.isEmpty, !email.isEmpty, !token.isEmpty else {
            return .failure(JiraError.missingCredentials)
        }
        
        let loginString = "\(email):\(token)"
        guard let loginData = loginString.data(using: .utf8) else { return .failure(JiraError.invalidURL) }
        let base64Auth = loginData.base64EncodedString()
        
        let cleanedKey = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard let url = URL(string: "https://\(domain).atlassian.net/rest/api/3/issue/\(cleanedKey)") else {
            return .failure(JiraError.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(URLError(.badServerResponse))
            }
            
            if httpResponse.statusCode == 404 {
                return .failure(NSError(domain: "Jira", code: 404, userInfo: [NSLocalizedDescriptionKey: "Chamado não encontrado. Verifique a chave."]))
            }
            
            guard httpResponse.statusCode == 200 else {
                return .failure(NSError(domain: "Jira", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Erro na API do Jira (\(httpResponse.statusCode))"]))
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return .success(json)
            } else {
                return .failure(NSError(domain: "Jira", code: -1, userInfo: [NSLocalizedDescriptionKey: "Falha ao decodificar resposta do Jira."]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    func fetchDashboardCounters(forceRefresh: Bool = false) async -> Result<[TicketType: Int], Error> {
        
        if !forceRefresh, let cachedData = cachedCounters, let lastFetch = lastCacheFetchTime {
            if Date().timeIntervalSince(lastFetch) < cacheExpirationInterval {
                print("🧠 DASHBOARD: Retornando volumetria diretamente do cache em memória.")
                return .success(cachedData)
            }
        }
        
        guard let domain = KeychainManager.get(key: "JIRA_DOMAIN"),
              let project = KeychainManager.get(key: "JIRA_PROJECT"),
              let email = KeychainManager.get(key: "JIRA_EMAIL"),
              let token = KeychainManager.get(key: "JIRA_TOKEN"),
              !domain.isEmpty, !project.isEmpty, !email.isEmpty, !token.isEmpty else {
            return .failure(JiraError.missingCredentials)
        }
        
        let loginString = "\(email):\(token)"
        guard let loginData = loginString.data(using: .utf8) else { return .failure(JiraError.invalidURL) }
        let base64Auth = loginData.base64EncodedString()
        
        var counters: [TicketType: Int] = [:]
        
        for type in TicketType.allCases {
            let jql = "project = '\(project)' AND issuetype = '\(type.rawValue)' AND statusCategory != Done"
            
            guard let url = URL(string: "https://\(domain).atlassian.net/rest/api/3/search/approximate-count") else {
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let bodyDict = ["jql": jql]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: bodyDict) else { continue }
            request.httpBody = jsonData
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { continue }
                
                if httpResponse.statusCode != 200 {
                    print("⚠️ Erro API Jira Status: \(httpResponse.statusCode) para o tipo \(type.rawValue)")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("Contexto do erro no backend: \(errorString)")
                    }
                    continue
                }
                
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let count = json["count"] as? Int {
                    counters[type] = count
                }
            } catch {
                print("❌ Falha de conexão na JQL: \(error.localizedDescription)")
                return .failure(error)
            }
        }
        
        self.cachedCounters = counters
        self.lastCacheFetchTime = Date()
        print("💾 DASHBOARD: Busca concluída. Cache local sincronizado e válido por 5 minutos.")
        
        return .success(counters)
    }
}
