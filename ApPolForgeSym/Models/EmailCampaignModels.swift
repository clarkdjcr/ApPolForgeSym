//
//  EmailCampaignModels.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//

import Foundation

// MARK: - Email Template

/// Pre-built email structures for campaign communication.
enum EmailTemplate: String, Codable, CaseIterable, Identifiable {
    case briefing      = "Campaign Briefing"
    case pollingUpdate = "Polling Update"
    case issueAlert    = "Issue Alert"
    case fullReport    = "Full Campaign Report"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .briefing:      return "doc.text.fill"
        case .pollingUpdate: return "chart.line.uptrend.xyaxis"
        case .issueAlert:    return "exclamationmark.triangle.fill"
        case .fullReport:    return "doc.richtext.fill"
        }
    }

    var description: String {
        switch self {
        case .briefing:      return "Daily campaign summary with key metrics"
        case .pollingUpdate: return "Focused on latest poll averages and trends"
        case .issueAlert:    return "Highlights top-sensitivity issue movements"
        case .fullReport:    return "Comprehensive report with all sections"
        }
    }

    /// Which content sections are enabled by default for this template.
    var defaultIncludePollData: Bool {
        switch self {
        case .pollingUpdate, .fullReport: return true
        case .briefing:                   return true
        case .issueAlert:                 return false
        }
    }

    var defaultIncludeIssueAlerts: Bool {
        switch self {
        case .issueAlert, .fullReport: return true
        case .briefing:                return true
        case .pollingUpdate:           return false
        }
    }

    var defaultIncludeNewsDigest: Bool {
        switch self {
        case .fullReport, .briefing: return true
        default:                     return false
        }
    }
}

// MARK: - Campaign Email

/// A generated campaign intelligence email ready to send via Mail.app.
struct CampaignEmail: Identifiable, Codable {
    let id: UUID
    var subject: String
    var recipientAddresses: [String]
    var template: EmailTemplate
    var includePollData: Bool
    var includeIssueAlerts: Bool
    var includeNewsDigest: Bool
    var includeWinProbability: Bool
    /// Optional reference to the UserCandidate this email is about
    var candidateId: UUID?
    var generatedAt: Date
    /// HTML content for Mail.app rich-text send
    var htmlBody: String
    /// Plain-text fallback (clipboard on visionOS)
    var plainTextBody: String

    var recipientList: String {
        recipientAddresses.joined(separator: ", ")
    }

    var isReadyToSend: Bool {
        !subject.isEmpty && !recipientAddresses.isEmpty && !plainTextBody.isEmpty
    }

    init(
        id: UUID = UUID(),
        subject: String = "",
        recipientAddresses: [String] = [],
        template: EmailTemplate = .briefing,
        includePollData: Bool = true,
        includeIssueAlerts: Bool = true,
        includeNewsDigest: Bool = true,
        includeWinProbability: Bool = true,
        candidateId: UUID? = nil,
        generatedAt: Date = Date(),
        htmlBody: String = "",
        plainTextBody: String = ""
    ) {
        self.id = id
        self.subject = subject
        self.recipientAddresses = recipientAddresses
        self.template = template
        self.includePollData = includePollData
        self.includeIssueAlerts = includeIssueAlerts
        self.includeNewsDigest = includeNewsDigest
        self.includeWinProbability = includeWinProbability
        self.candidateId = candidateId
        self.generatedAt = generatedAt
        self.htmlBody = htmlBody
        self.plainTextBody = plainTextBody
    }
}
