//
//  GigBuddyApp.swift
//  GigBuddy
//
//  Created by Paul Barnes on 23/04/2025.
//

import SwiftUI

@main
struct GigBuddyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Configure app information
extension Bundle {
    static var appName: String { Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "GigBuddy" }
    static var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
    static var buildNumber: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1" }
}

// Add location usage descriptions to Info.plist
extension Bundle {
    static var locationUsageDescription: String { "GigBuddy uses your location to find concerts and events near you." }
    static var locationWhenInUseUsageDescription: String { "GigBuddy uses your location to find concerts and events near you." }
}
