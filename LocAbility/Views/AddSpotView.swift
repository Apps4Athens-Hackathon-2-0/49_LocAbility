//
//  AddSpotView.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Form to add new accessibility spot with photo/voice input
//

import SwiftUI
import PhotosUI

struct AddSpotView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var spotsManager: AccessibilitySpotsManager
    @EnvironmentObject var locationManager: LocationManager

    @StateObject private var viewModel = AddSpotViewModel()

    @State private var selectedType: SpotType = .ramp
    @State private var description: String = ""
    @State private var status: SpotStatus = .working
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoImage: UIImage?
    @State private var isRecording = false
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                // Type Selection
                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach(SpotType.allCases, id: \.self) { type in
                            HStack(spacing: 8) {
                                Text(type.emoji)
                                    .font(.system(size: 20))
                                Text(type.rawValue)
                                    .fontWeight(.medium)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .accessibilityLabel("Select accessibility feature type")
                } header: {
                    Text("Feature Type")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                // Description
                Section {
                    TextField("Describe the accessibility feature...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Description")
                        .accessibilityHint("Describe the condition and location of this feature")
                } header: {
                    Text("Description")
                } footer: {
                    Text("Optional: Add details about condition, location, etc.")
                }

                // Photo Input
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.blue)
                            Text("Add Photo")
                            Spacer()
                            if photoImage != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .accessibilityLabel("Add photo of accessibility feature")
                    .accessibilityValue(photoImage != nil ? "Photo selected" : "No photo")

                    if let photoImage {
                        Image(uiImage: photoImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                            .accessibilityLabel("Selected photo preview")
                    }
                } header: {
                    Text("Photo (Optional)")
                }

                // Voice Input
                Section {
                    Button {
                        toggleVoiceRecording()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(isRecording ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(isRecording ? .red : .blue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(isRecording ? "Stop Recording" : "Record Voice Description")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                if isRecording {
                                    Text("Listening...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            if isRecording {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .accessibilityLabel(isRecording ? "Stop voice recording" : "Start voice recording")
                    .accessibilityHint("Describe the spot using your voice")

                    if !viewModel.voiceTranscript.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Transcript:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            Text(viewModel.voiceTranscript)
                                .font(.subheadline)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.08))
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Voice transcript: \(viewModel.voiceTranscript)")
                    }
                } header: {
                    Text("Voice Description (Optional)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                } footer: {
                    Text("🤖 Speak to describe the feature. AI will classify it automatically using on-device processing.")
                        .font(.caption)
                }

                // Status
                Section {
                    Picker("Status", selection: $status) {
                        ForEach(SpotStatus.allCases, id: \.self) { status in
                            HStack {
                                Image(systemName: status.icon)
                                Text(status.rawValue)
                            }
                            .tag(status)
                        }
                    }
                    .accessibilityLabel("Current status of this feature")
                } header: {
                    Text("Current Status")
                }

                // AI Classification Preview
                if viewModel.isClassifying {
                    Section {
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI is analyzing...")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("On-device processing")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                                .foregroundColor(.blue.opacity(0.6))
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("🧠 AI Classification")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Add Accessibility Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel and close")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        addSpot()
                    } label: {
                        Text("Add")
                            .fontWeight(.bold)
                    }
                    .disabled(!isFormValid)
                    .accessibilityLabel("Add spot to map")
                    .accessibilityHint(isFormValid ? "Save this accessibility spot" : "Complete the form to add spot")
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        photoImage = image
                        await viewModel.classifyImage(image)
                    }
                }
            }
            .alert("Spot Added!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your accessibility spot has been added to the map. Thank you for contributing!")
            }
        }
    }

    var isFormValid: Bool {
        // At minimum, we need a type selected
        true
    }

    private func toggleVoiceRecording() {
        if isRecording {
            viewModel.stopRecording()
            isRecording = false
        } else {
            viewModel.startRecording()
            isRecording = true
        }
    }

    private func addSpot() {
        let finalDescription = !description.isEmpty ? description :
                              !viewModel.voiceTranscript.isEmpty ? viewModel.voiceTranscript :
                              selectedType.rawValue

        let newSpot = AccessibilitySpot(
            title: selectedType.rawValue,
            description: finalDescription,
            type: selectedType,
            status: status,
            coordinate: locationManager.region.center,
            photo: photoImage,
            distance: nil
        )

        spotsManager.addSpot(newSpot)
        showingSuccess = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    AddSpotView()
        .environmentObject(AccessibilitySpotsManager())
        .environmentObject(LocationManager())
}
