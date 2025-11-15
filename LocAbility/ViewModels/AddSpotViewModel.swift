//
//  AddSpotViewModel.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  ViewModel for adding spots with AI classification
//

import Foundation
import SwiftUI
import AVFoundation
import Speech
import Vision
import CoreML
import NaturalLanguage

@MainActor
class AddSpotViewModel: NSObject, ObservableObject {
    @Published var voiceTranscript = ""
    @Published var isClassifying = false
    @Published var classifiedType: SpotType?

    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    // MARK: - Enhanced Voice Recording with Speech Framework

    func startRecording() {
        // Request authorization
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self.beginRecording()
                } else {
                    print("⚠️ Speech recognition not authorized: \(status)")
                    // Provide user feedback
                    self.voiceTranscript = "Please enable speech recognition in Settings"
                }
            }
        }
    }

    private func beginRecording() {
        print("🎤 Starting voice recording...")

        // Setup audio session with proper error handling
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session error: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ Unable to create recognition request")
            return
        }

        // Enable on-device recognition for privacy
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true

        // Add context words for better accuracy
        let contextualStrings = ["ramp", "elevator", "wheelchair", "accessible", "entrance", "parking", "toilet", "step-free"]
        recognitionRequest.contextualStrings = contextualStrings

        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("✅ Audio engine started")
        } catch {
            print("❌ Audio engine error: \(error)")
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                Task { @MainActor in
                    let transcript = result.bestTranscription.formattedString
                    self.voiceTranscript = transcript

                    // Show confidence level
                    let segments = result.bestTranscription.segments
                    let avgConfidence = segments.isEmpty ? 0 : segments.map { $0.confidence }.reduce(0, +) / Float(segments.count)
                    print("🎯 Transcription confidence: \(Int(avgConfidence * 100))%")

                    // Auto-classify when user pauses (finalized result)
                    if result.isFinal {
                        print("✅ Final transcription: \(transcript)")
                        await self.classifyText(transcript)

                        // Also try Core ML classification
                        let (mlType, mlConfidence) = CoreMLClassifier.classifyDescription(transcript)
                        if let mlType = mlType {
                            print("🤖 Core ML suggests: \(mlType.rawValue) (confidence: \(Int(mlConfidence * 100))%)")
                        }
                    }
                }
            }

            if let error = error {
                print("❌ Recognition error: \(error)")
                self.stopRecording()
            }
        }
    }

    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
    }

    // MARK: - AI Classification with Natural Language

    func classifyText(_ text: String) async {
        isClassifying = true
        defer { isClassifying = false }

        // Use Natural Language framework for better understanding
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = text

        // Extract important nouns and entities
        var keywords: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .lexicalClass) { tag, range in
            if tag == .noun || tag == .verb {
                keywords.append(String(text[range]).lowercased())
            }
            return true
        }

        // Sentiment analysis (placeholder for future custom model)
        // In production, you would use a custom trained sentiment model
        let sentiment = "neutral"

        // Advanced classification using keywords and context
        let lowercased = text.lowercased()
        var scores: [SpotType: Double] = [
            .ramp: 0,
            .elevator: 0,
            .accessibleEntrance: 0,
            .stepFreeRoute: 0,
            .accessibleParking: 0,
            .accessibleToilet: 0
        ]

        // Ramp keywords
        let rampKeywords = ["ramp", "slope", "incline", "gradient", "wheelchair access"]
        for keyword in rampKeywords {
            if lowercased.contains(keyword) {
                scores[.ramp, default: 0] += 1.0
            }
        }

        // Elevator keywords
        let elevatorKeywords = ["elevator", "lift", "vertical", "floors", "up", "down"]
        for keyword in elevatorKeywords {
            if lowercased.contains(keyword) {
                scores[.elevator, default: 0] += 1.0
            }
        }

        // Entrance keywords
        let entranceKeywords = ["entrance", "door", "entry", "access point", "way in"]
        for keyword in entranceKeywords {
            if lowercased.contains(keyword) {
                scores[.accessibleEntrance, default: 0] += 1.0
            }
        }

        // Parking keywords
        let parkingKeywords = ["parking", "park", "spot", "space", "car"]
        for keyword in parkingKeywords {
            if lowercased.contains(keyword) {
                scores[.accessibleParking, default: 0] += 1.0
            }
        }

        // Toilet keywords
        let toiletKeywords = ["toilet", "bathroom", "restroom", "wc", "lavatory"]
        for keyword in toiletKeywords {
            if lowercased.contains(keyword) {
                scores[.accessibleToilet, default: 0] += 1.0
            }
        }

        // Route keywords
        let routeKeywords = ["path", "route", "way", "step-free", "walkway", "sidewalk"]
        for keyword in routeKeywords {
            if lowercased.contains(keyword) {
                scores[.stepFreeRoute, default: 0] += 1.0
            }
        }

        // Get highest scoring type
        if let bestMatch = scores.max(by: { $0.value < $1.value }), bestMatch.value > 0 {
            classifiedType = bestMatch.key
        }

        // Log classification for debugging
        print("📊 NL Classification scores: \(scores)")
        print("🎯 Selected type: \(classifiedType?.rawValue ?? "none")")
        print("💭 Sentiment: \(sentiment ?? "neutral")")
    }

    func classifyImage(_ image: UIImage) async {
        isClassifying = true
        defer { isClassifying = false }

        guard let cgImage = image.cgImage else { return }

        // Use Vision framework to detect features
        let request = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNRectangleObservation] else {
                return
            }

            Task { @MainActor in
                // Analyze detected rectangles to identify ramps, elevators, etc.
                // This is a simplified version - in production you'd use trained ML models
                if !observations.isEmpty {
                    // Detected some rectangular structures
                    // Could be a ramp, elevator, or accessible entrance
                    self.classifiedType = .ramp
                }
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])

        // In a real app, you would use a custom Core ML model trained on accessibility features
        // Example:
        // let model = try? VNCoreMLModel(for: AccessibilityFeatureClassifier().model)
        // let request = VNCoreMLRequest(model: model) { request, error in
        //     // Handle classification results
        // }
    }
}
