//
//  VariantPhoto.swift
//  CaliCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-25.
//


import Foundation
import SwiftData

@Model
class VariantPhoto {
    var id: UUID
    var variantUuid: String
    var imageData: Data
    var caption: String?
    var capturedDate: Date
    var sortOrder: Int
    
    init(variantUuid: String, imageData: Data, caption: String? = nil, sortOrder: Int = 0) {
        self.id = UUID()
        self.variantUuid = variantUuid
        self.imageData = imageData
        self.caption = caption
        self.capturedDate = Date()
        self.sortOrder = sortOrder
    }
}
