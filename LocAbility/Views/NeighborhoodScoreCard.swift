//
//  NeighborhoodScoreCard.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Displays accessibility score for current area
//

import SwiftUI

struct NeighborhoodScoreCard: View {
    let score: Int

    var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 50...79: return .orange
        default: return .red
        }
    }

    var scoreDescription: String {
        switch score {
        case 80...100: return "Excellent accessibility"
        case 50...79: return "Moderate accessibility"
        case 1...49: return "Limited accessibility"
        default: return "No data available"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Area Accessibility")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(scoreDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Score Display
            ZStack {
                // Background ring
                Circle()
                    .stroke(scoreColor.opacity(0.15), lineWidth: 10)
                    .frame(width: 80, height: 80)

                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(
                        LinearGradient(
                            colors: [scoreColor, scoreColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: score)
                    .shadow(color: scoreColor.opacity(0.3), radius: 4, x: 0, y: 2)

                VStack(spacing: -2) {
                    Text("\(score)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)

                    Text("/100")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Area accessibility score: \(score) out of 100. \(scoreDescription)")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    VStack {
        NeighborhoodScoreCard(score: 85)
        NeighborhoodScoreCard(score: 65)
        NeighborhoodScoreCard(score: 30)
    }
    .padding()
}
