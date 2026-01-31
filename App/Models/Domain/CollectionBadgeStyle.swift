//
//  CollectionBadgeStyle.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-30.
//


//
//  CollectionBadgeStyle.swift
//  LottaPaws
//

import Foundation

/// Controls what count (if any) is displayed on the Collection tab badge
enum CollectionBadgeStyle: String, CaseIterable {
    case off = "off"
    case critters = "critters"    // Unique critters owned
    case variants = "variants"     // Total variants owned
    
    var displayName: String {
        switch self {
        case .off: return "Off"
        case .critters: return "Unique Critters"
        case .variants: return "Total Variants"
        }
    }
}