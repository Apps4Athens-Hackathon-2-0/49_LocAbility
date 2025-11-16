//
//  CoreMLClassifier.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Core ML + Vision Framework for accessibility classification
//

import Foundation
import CoreML
import NaturalLanguage
import Vision
import UIKit

class CoreMLClassifier {

    /// Classify accessibility feature description using Core ML
    /// This uses Apple's built-in text classifier as a demonstration
    /// In production, you would train a custom model with CreateML
    static func classifyDescription(_ text: String) -> (type: SpotType?, confidence: Double) {
        // Use Natural Language's built-in classifier
        // In production, replace with custom Core ML model trained on accessibility descriptions

        let embedding = NLEmbedding.wordEmbedding(for: .english)

        // Calculate semantic similarity scores for each category
        var scores: [SpotType: Double] = [:]

        // Reference descriptions for each type
        let referenceDescriptions: [SpotType: [String]] = [
            .ramp: ["ramp", "slope", "incline", "wheelchair ramp", "accessible ramp"],
            .elevator: ["elevator", "lift", "vertical transport", "elevator access"],
            .accessibleEntrance: ["entrance", "accessible door", "automatic door", "entrance ramp"],
            .stepFreeRoute: ["path", "walkway", "route", "step-free path", "sidewalk"],
            .accessibleParking: ["parking", "accessible parking", "disabled parking", "parking space"],
            .accessibleToilet: ["toilet", "restroom", "bathroom", "accessible toilet", "WC"]
        ]

        // Tokenize input
        let inputTokens = text.lowercased().components(separatedBy: .whitespaces)

        // Calculate similarity for each type
        for (type, references) in referenceDescriptions {
            var typeScore: Double = 0

            for reference in references {
                let refTokens = reference.components(separatedBy: .whitespaces)

                // Check for direct matches
                for inputToken in inputTokens {
                    if refTokens.contains(inputToken) {
                        typeScore += 2.0
                    }

                    // Check semantic similarity using embeddings
                    if let embedding = embedding {
                        for refToken in refTokens {
                            let similarity = embedding.distance(between: inputToken, and: refToken)
                            // Smaller distance = higher similarity
                            let normalizedSimilarity = max(0, 1.0 - similarity)
                            typeScore += normalizedSimilarity
                        }
                    }
                }
            }

            scores[type] = typeScore
        }

        // Get best match
        guard let bestMatch = scores.max(by: { $0.value < $1.value }) else {
            return (nil, 0.0)
        }

        // Calculate confidence (normalize to 0-1)
        let totalScore = scores.values.reduce(0, +)
        let confidence = totalScore > 0 ? bestMatch.value / totalScore : 0.0

        // Only return if confidence is above threshold
        if confidence > 0.3 {
            return (bestMatch.key, confidence)
        }

        return (nil, 0.0)
    }

    /// Train custom model (placeholder for future implementation)
    /// In production, use CreateML to train on labeled accessibility descriptions
    static func trainCustomModel(trainingData: [(text: String, label: SpotType)]) {
        // This would be implemented with CreateML
        // Example:
        // let trainingDataSource = MLDataTable(...)
        // let textClassifier = try MLTextClassifier(trainingData: trainingDataSource, ...)
        // try textClassifier.write(to: URL(...))

        print("📚 Custom model training would happen here")
        print("   Training data size: \(trainingData.count)")
    }

    // MARK: - Vision Framework Detection

    /// Enhanced classification combining image and text analysis
    static func classifyAccessibilityFeature(image: UIImage, description: String?) async throws -> (type: SpotType, confidence: Float, detectedFeatures: [String]) {
        guard let ciImage = CIImage(image: image) else {
            throw NSError(domain: "CoreMLClassifier", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }

        var detectedFeatures: [String] = []
        var suggestedType: SpotType?
        var confidence: Float = 0.0

        // 1. Detect rectangles (doors, signs, ramps)
        let rectangles = try await detectRectangles(in: ciImage)
        if !rectangles.isEmpty {
            detectedFeatures.append("\(rectangles.count) rectangular structures")
            print("📐 Detected \(rectangles.count) rectangles")
        }

        // 2. Recognize text (accessibility signs)
        let texts = try await recognizeText(in: ciImage)
        if !texts.isEmpty {
            detectedFeatures.append(contentsOf: texts)
            print("📝 Recognized: \(texts.joined(separator: ", "))")

            if let type = analyzeTextForAccessibility(texts) {
                suggestedType = type
                confidence = 0.85
            }
        }

        // 3. Analyze description if provided
        if let desc = description, !desc.isEmpty {
            if let textType = classifyFromDescription(desc) {
                if suggestedType == nil || confidence < 0.8 {
                    suggestedType = textType
                    confidence = 0.8
                }
            }
        }

        // 4. Scene classification
        let scene = try await classifyScene(in: ciImage)
        if let sceneLabel = scene {
            detectedFeatures.append("Scene: \(sceneLabel)")
            print("🏙️ Scene: \(sceneLabel)")
        }

        // Return result with fallback to ramp
        let finalType = suggestedType ?? .ramp
        let finalConfidence = confidence > 0 ? confidence : 0.4

        return (finalType, finalConfidence, detectedFeatures)
    }

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

    private static func analyzeTextForAccessibility(_ texts: [String]) -> SpotType? {
        let combinedText = texts.joined(separator: " ")

        let keywords: [SpotType: [String]] = [
            .elevator: ["elevator", "lift", "↑", "↓", "floor", "level"],
            .accessibleEntrance: ["entrance", "entry", "accessible", "wheelchair", "automatic", "door"],
            .accessibleParking: ["parking", "park", "disabled", "handicap", "p", "reserved"],
            .accessibleToilet: ["toilet", "wc", "restroom", "bathroom", "accessible"],
            .ramp: ["ramp", "slope", "incline", "wheelchair access"],
            .stepFreeRoute: ["step-free", "no steps", "level", "flat"]
        ]

        var bestMatch: SpotType?
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

    static func classifyFromDescription(_ description: String) -> SpotType? {
        let (type, confidence) = classifyDescription(description)
        return confidence > 0.3 ? type : nil
    }
}
