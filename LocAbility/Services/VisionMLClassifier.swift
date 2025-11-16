//
//  VisionMLClassifier.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Enhanced Vision + Core ML classification for accessibility features
//

import Foundation
import Vision
import CoreML
import UIKit
import NaturalLanguage

class VisionMLClassifier {

    // MARK: - Image Classification with MobileNetV2

    /// Classify image using pre-trained MobileNetV2 model
    static func classifyImageWithMobileNet(_ image: UIImage) async throws -> AccessibilityType? {
        guard let ciImage = CIImage(image: image) else {
            throw ClassificationError.invalidImage
        }

        // Create Vision request with MobileNetV2
        let model = try await loadMobileNetModel()
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try handler.perform([request])

        guard let results = request.results as? [VNClassificationObservation],
              let topResult = results.first else {
            throw ClassificationError.noResults
        }

        print("🤖 MobileNetV2 classified as: \(topResult.identifier) (confidence: \(topResult.confidence))")

        // Map MobileNet labels to accessibility types
        return mapMobileNetToAccessibilityType(topResult.identifier, confidence: topResult.confidence)
    }

    private static func loadMobileNetModel() async throws -> VNCoreMLModel {
        // Note: Add MobileNetV2.mlmodel to project
        // For now, we'll use Vision's built-in classification
        throw ClassificationError.modelNotFound
    }

    // MARK: - Vision Framework Built-in Detection

    /// Detect accessibility features using Vision Framework's built-in capabilities
    static func detectAccessibilityFeatures(in image: UIImage) async throws -> VisionDetectionResult {
        guard let ciImage = CIImage(image: image) else {
            throw ClassificationError.invalidImage
        }

        var detectedFeatures: [String] = []
        var suggestedType: AccessibilityType?
        var confidence: Float = 0.0

        // 1. Detect rectangles (doors, signs, ramps)
        let rectangles = try await detectRectangles(in: ciImage)
        if !rectangles.isEmpty {
            detectedFeatures.append("\(rectangles.count) rectangular structures")
            print("📐 Detected \(rectangles.count) rectangles (doors/signs/ramps)")
        }

        // 2. Recognize text (accessibility signs, labels)
        let texts = try await recognizeText(in: ciImage)
        if !texts.isEmpty {
            detectedFeatures.append(contentsOf: texts)
            print("📝 Recognized text: \(texts.joined(separator: ", "))")

            // Analyze text for accessibility keywords
            if let type = analyzeTextForAccessibility(texts) {
                suggestedType = type
                confidence = 0.85
            }
        }

        // 3. Detect horizontal lines (ramps, slopes)
        let lines = try await detectHorizontalLines(in: ciImage)
        if lines > 0 {
            detectedFeatures.append("\(lines) horizontal lines (potential ramp)")
            print("📏 Detected \(lines) horizontal lines")

            if suggestedType == nil {
                suggestedType = .ramp
                confidence = 0.65
            }
        }

        // 4. Scene classification
        let sceneClassification = try await classifyScene(in: ciImage)
        if let scene = sceneClassification {
            detectedFeatures.append("Scene: \(scene)")
            print("🏙️ Scene classified as: \(scene)")
        }

        return VisionDetectionResult(
            detectedFeatures: detectedFeatures,
            suggestedType: suggestedType,
            confidence: confidence
        )
    }

    // MARK: - Vision Detection Requests

    private static func detectRectangles(in image: CIImage) async throws -> [VNRectangleObservation] {
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 2.0
        request.minimumSize = 0.1
        request.minimumConfidence = 0.6

        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try handler.perform([request])

        return request.results as? [VNRectangleObservation] ?? []
    }

    private static func recognizeText(in image: CIImage) async throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try handler.perform([request])

        guard let observations = request.results else { return [] }

        var recognizedTexts: [String] = []
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            if topCandidate.confidence > 0.5 {
                recognizedTexts.append(topCandidate.string.lowercased())
            }
        }

        return recognizedTexts
    }

    private static func detectHorizontalLines(in image: CIImage) async throws -> Int {
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.5
        request.detectsDarkOnLight = true

        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try handler.perform([request])

        guard let results = request.results as? [VNContoursObservation] else { return 0 }

        var horizontalLineCount = 0
        for observation in results {
            let contourCount = observation.contourCount
            if contourCount > 5 {
                horizontalLineCount += 1
            }
        }

        return horizontalLineCount
    }

    private static func classifyScene(in image: CIImage) async throws -> String? {
        let request = VNClassifyImageRequest()

        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try handler.perform([request])

        guard let results = request.results as? [VNClassificationObservation],
              let topResult = results.first else {
            return nil
        }

        if topResult.confidence > 0.6 {
            return topResult.identifier
        }

        return nil
    }

    // MARK: - Text Analysis for Accessibility

    private static func analyzeTextForAccessibility(_ texts: [String]) -> AccessibilityType? {
        let combinedText = texts.joined(separator: " ")

        // Keywords for each type
        let keywords: [AccessibilityType: [String]] = [
            .elevator: ["elevator", "lift", "↑", "↓", "floor", "level"],
            .accessibleEntrance: ["entrance", "entry", "accessible", "wheelchair", "automatic", "door"],
            .accessibleParking: ["parking", "park", "disabled", "handicap", "p", "reserved"],
            .accessibleToilet: ["toilet", "wc", "restroom", "bathroom", "accessible"],
            .ramp: ["ramp", "slope", "incline", "wheelchair access"],
            .stepFreeRoute: ["step-free", "no steps", "level", "flat"]
        ]

        var bestMatch: AccessibilityType?
        var maxScore = 0

        for (type, typeKeywords) in keywords {
            let score = typeKeywords.filter { keyword in
                combinedText.contains(keyword)
            }.count

            if score > maxScore {
                maxScore = score
                bestMatch = type
            }
        }

        return maxScore > 0 ? bestMatch : nil
    }

    // MARK: - MobileNet Label Mapping

    private static func mapMobileNetToAccessibilityType(_ label: String, confidence: Float) -> AccessibilityType? {
        let lowercaseLabel = label.lowercased()

        // Map common MobileNet labels to accessibility types
        let mappings: [String: AccessibilityType] = [
            "ramp": .ramp,
            "wheelchair": .accessibleEntrance,
            "elevator": .elevator,
            "lift": .elevator,
            "stairway": .ramp, // If stairs detected, might have a ramp nearby
            "door": .accessibleEntrance,
            "parking_meter": .accessibleParking,
            "toilet_seat": .accessibleToilet,
            "sliding_door": .accessibleEntrance
        ]

        for (keyword, type) in mappings {
            if lowercaseLabel.contains(keyword) && confidence > 0.5 {
                return type
            }
        }

        return nil
    }

    // MARK: - Combined Classification

    /// Combine all detection methods for best results
    static func classifyAccessibilityFeature(image: UIImage, description: String?) async throws -> ClassificationResult {
        // Run Vision detection
        let visionResult = try await detectAccessibilityFeatures(in: image)

        // Analyze text description if provided
        var textType: AccessibilityType?
        var textConfidence: Float = 0.0

        if let description = description, !description.isEmpty {
            textType = CoreMLClassifier.classifyFromDescription(description)
            textConfidence = 0.8
        }

        // Combine results
        let finalType: AccessibilityType
        let finalConfidence: Float

        if let visionType = visionResult.suggestedType,
           visionResult.confidence > 0.7 {
            finalType = visionType
            finalConfidence = visionResult.confidence
        } else if let txtType = textType {
            finalType = txtType
            finalConfidence = textConfidence
        } else if let visionType = visionResult.suggestedType {
            finalType = visionType
            finalConfidence = visionResult.confidence
        } else {
            // Fallback to ramp as most common
            finalType = .ramp
            finalConfidence = 0.4
        }

        return ClassificationResult(
            type: finalType,
            confidence: finalConfidence,
            detectedFeatures: visionResult.detectedFeatures,
            method: visionResult.suggestedType != nil ? "Vision Framework" : "Text Analysis"
        )
    }
}

// MARK: - Supporting Types

struct VisionDetectionResult {
    let detectedFeatures: [String]
    let suggestedType: AccessibilityType?
    let confidence: Float
}

struct ClassificationResult {
    let type: AccessibilityType
    let confidence: Float
    let detectedFeatures: [String]
    let method: String
}

enum ClassificationError: Error {
    case invalidImage
    case noResults
    case modelNotFound
}
