//
//  AppLogger.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-27.
//


import Foundation
import os.log

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.calicollection"
    
    private static let general = os.Logger(subsystem: subsystem, category: "general")
    private static let network = os.Logger(subsystem: subsystem, category: "network")
    private static let sync = os.Logger(subsystem: subsystem, category: "sync")
    
    // MARK: - General Logging
    
    static func debug(_ message: String) {
        #if DEBUG
        general.debug("🔍 \(message)")
        #endif
    }
    
    static func info(_ message: String) {
        #if DEBUG
        general.info("ℹ️ \(message)")
        #endif
    }
    
    static func warning(_ message: String) {
        general.warning("⚠️ \(message)")
    }
    
    static func error(_ message: String) {
        general.error("❌ \(message)")
    }
    
    // MARK: - Network Logging
    
    static func networkRequest(_ url: String) {
        #if DEBUG
        network.debug("🌐 Request: \(url)")
        #endif
    }
    
    static func networkResponse(status: Int, url: String) {
        #if DEBUG
        network.debug("📡 Response \(status): \(url)")
        #endif
    }
    
    static func networkSuccess(_ message: String) {
        #if DEBUG
        network.debug("✅ \(message)")
        #endif
    }
    
    static func networkError(_ message: String) {
        network.error("❌ \(message)")
    }
    
    // MARK: - Sync Logging
    
    static func syncStart(_ type: String) {
        #if DEBUG
        sync.debug("🔄 Starting \(type) sync...")
        #endif
    }
    
    static func syncComplete(_ message: String) {
        #if DEBUG
        sync.debug("✅ \(message)")
        #endif
    }
    
    static func syncSkipped(_ reason: String) {
        #if DEBUG
        sync.debug("⏭️ Sync skipped: \(reason)")
        #endif
    }
    
    static func syncError(_ message: String) {
        sync.error("❌ Sync failed: \(message)")
    }
}