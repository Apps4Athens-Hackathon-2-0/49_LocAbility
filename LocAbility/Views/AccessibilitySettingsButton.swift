//
//  AccessibilitySettingsButton.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Button to toggle accessibility settings
//

import SwiftUI

struct AccessibilitySettingsButton: View {
    @State private var showingSettings = false

    var body: some View {
        Button {
            showingSettings = true
        } label: {
            Image(systemName: "accessibility")
        }
        .accessibilityLabel("Accessibility settings")
        .accessibilityHint("Open accessibility preferences")
        .sheet(isPresented: $showingSettings) {
            AccessibilitySettingsView()
        }
    }
}

struct AccessibilitySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("highContrastMode") private var highContrastMode = false
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("largerText") private var largerText = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("High Contrast Mode", isOn: $highContrastMode)
                        .accessibilityLabel("High contrast mode")
                        .accessibilityHint("Increases color contrast for better visibility")

                    Toggle("Reduce Motion", isOn: $reduceMotion)
                        .accessibilityLabel("Reduce motion")
                        .accessibilityHint("Minimizes animations and transitions")

                    Toggle("Larger Text", isOn: $largerText)
                        .accessibilityLabel("Larger text")
                        .accessibilityHint("Increases default text size")
                } header: {
                    Text("Visual Accessibility")
                } footer: {
                    Text("These settings enhance the app's accessibility for users with visual impairments.")
                }

                Section {
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        HStack {
                            Text("System Accessibility Settings")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                    .accessibilityLabel("Open system accessibility settings")
                } header: {
                    Text("System Settings")
                }

                Section {
                    Text("LocAbility is designed to be fully accessible with VoiceOver, Dynamic Type, and other iOS accessibility features.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("About Accessibility")
                }
            }
            .navigationTitle("Accessibility")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AccessibilitySettingsButton()
}
