//
//  CoreMLClassifier.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Core ML helper for on-device classification
//

import Foundation
import CoreML
import NaturalLanguage

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
}
