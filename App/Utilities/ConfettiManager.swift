//
//  ConfettiManager.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-29.
//


import SwiftUI

@MainActor
class ConfettiManager: ObservableObject {
    static let shared = ConfettiManager()
    
    @Published var isShowing = false
    
    private init() {}
    
    func trigger() {
        isShowing = true
    }
}