//
//  Item.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-20.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
