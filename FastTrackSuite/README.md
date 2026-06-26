# 🚀 FastTrack Suite for macOS

**FastTrack Suite** is a fully native macOS application built for **Support Analysts** and **Operations Teams**. Designed exclusively for **Jira Cloud**, it eliminates browser friction and transforms everyday support operations into a fast, seamless desktop experience.

Built entirely with **SwiftUI** and optimized for **Apple Silicon**, FastTrack Suite combines powerful workflow management with instant ticket creation, allowing your team to stay focused without leaving the desktop.

The application offers two seamless ways to work:

* 🖥️ **Full Desktop Experience** — A complete workspace for dashboards, ticket management, validation tools, and application settings.
* ⚡ **Quick Ticket Creator** — Create Jira issues instantly from the macOS menu bar without interrupting your workflow.

---

# ✨ Why FastTrack Suite?

Modern support teams deserve native tools.

FastTrack Suite replaces repetitive browser-based workflows with a fast, secure, and responsive macOS experience designed specifically for Jira Cloud.

Whether you're creating incidents, validating information, monitoring project queues, or managing operational requests, everything is just a few clicks away.

---

# ✨ Features

## 🚀 Built for Speed

Create and manage Jira issues without switching tabs or opening your browser.

Support for:

* Service Requests
* Incidents
* Tasks
* Improvements

---

## 📊 Real-Time Project Insights

Monitor your project's workload through a live JQL dashboard powered by **Swift Charts**.

A native donut chart provides an instant overview of your active queue while consuming minimal system resources.

---

## ⚡ Intelligent Performance

A built-in smart caching layer automatically stores API responses for five minutes, dramatically reducing unnecessary requests.

Benefits include:

* Faster response times
* Lower battery consumption
* Reduced Atlassian API usage
* Protection against rate limiting

---

## 🔐 Enterprise-Grade Security

Your Jira credentials are protected using Apple's native security technologies.

FastTrack Suite supports:

* Touch ID authentication
* macOS password authentication
* Secure Keychain storage

No credentials are ever stored in plain text.

---

## 🌍 Ready for Global Teams

Localization is built into the application's architecture using Apple's modern **String Catalogs**.

Supported languages:

* 🇺🇸 English
* 🇧🇷 Portuguese (Brazil)

---

# 🛠️ Built with Modern Apple Technologies

FastTrack Suite embraces the latest macOS development frameworks.

### User Interface

* SwiftUI
* Swift Charts

### Networking

* URLSession
* Async/Await
* Jira Cloud REST API v3

### Security

* LocalAuthentication
* macOS Keychain

### Navigation

* NavigationSplitView

### Localization

* String Catalogs (.xcstrings)

---

# 💻 System Requirements

| Requirement      | Specification                                |
| ---------------- | -------------------------------------------- |
| Operating System | macOS 14 Sonoma or later                     |
| Processor        | Apple Silicon (M1, M2, M3, or newer)         |
| Permissions      | Standard access to the user's Login Keychain |

---

# ⚙️ Getting Started

Connecting FastTrack Suite to Jira Cloud takes only a few minutes.

You'll need:

* Atlassian Account Email
* Atlassian API Token
* Jira Subdomain
* Project Key

## Generate an Atlassian API Token

1. Sign in to your Atlassian account.
2. Open **Account Settings → Security → API Tokens**.
3. Click **Create API Token**.
4. Give your token a recognizable name.
5. Copy the generated token.

> **Important:** Atlassian only displays the token once.

---

## Find Your Jira Subdomain

Example:

```
https://my-company.atlassian.net
```

Subdomain:

```
my-company
```

---

## Find Your Project Key

Example:

```
SUP-1234
```

Project Key:

```
SUP
```

---

# 🗺️ Roadmap

FastTrack Suite was designed with scalability in mind.

### 📱 Native iPhone Companion

Bring your Jira workflows to iPhone with native ticket management and SLA notifications.

### 📦 Shared Business Core

Extract networking and security components into a reusable Swift Package shared between macOS and iOS.

### 📈 Advanced Analytics

Expand the dashboard with SLA monitoring, issue category metrics, and operational insights.

---

# ❤️ Designed for macOS

FastTrack Suite isn't a web application wrapped in a native shell.

It's a true macOS experience designed to feel at home on Apple's platform, delivering the speed, responsiveness, and polish users expect from native software.

---

# 📄 License

Distributed under the MIT License. See the `LICENSE` file for more information.
