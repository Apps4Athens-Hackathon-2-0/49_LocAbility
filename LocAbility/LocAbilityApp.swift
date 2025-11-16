//
//  LocAbilityApp.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Athens Accessibility Map - Empowering citizens with accessible mobility
//

import SwiftUI
import FirebaseCore

@main
struct LocAbilityApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var spotsManager = AccessibilitySpotsManager()

    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        print("🔥 Firebase initialized successfully")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(spotsManager)
                // Enable Dynamic Type for text scaling
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }
}
