//
//  ReportRequest.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-26.
//


import Foundation

struct ReportRequest: Codable {
    let variantUuid: String
    let issueType: ReportIssueType
    let details: String?
    let suggestedCorrection: String?
    let deviceId: String
    
    enum CodingKeys: String, CodingKey {
        case variantUuid = "variant_uuid"
        case issueType = "issue_type"
        case details
        case suggestedCorrection = "suggested_correction"
        case deviceId = "device_id"
    }
}

enum ReportIssueType: String, Codable, CaseIterable {
    case incorrectImage = "incorrect_image"
    case incorrectName = "incorrect_name"
    case incorrectSet = "incorrect_set"
    case incorrectYear = "incorrect_year"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .incorrectImage: return "Incorrect Image"
        case .incorrectName: return "Incorrect Name"
        case .incorrectSet: return "Incorrect Set"
        case .incorrectYear: return "Incorrect Release Year"
        case .other: return "Other Issue"
        }
    }
    
    var icon: String {
        switch self {
        case .incorrectImage: return "photo"
        case .incorrectName: return "textformat"
        case .incorrectSet: return "square.stack.3d.up"
        case .incorrectYear: return "calendar"
        case .other: return "exclamationmark.circle"
        }
    }
}

struct ReportResponse: Codable {
    let message: String
        let data: ReportData
        
        struct ReportData: Codable {
            let uuid: String
        }

}
