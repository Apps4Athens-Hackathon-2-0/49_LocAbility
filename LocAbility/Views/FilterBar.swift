//
//  FilterBar.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Accessibility filter selection bar
//

import SwiftUI

struct FilterBar: View {
    @Binding var selectedFilter: AccessibilityFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AccessibilityFilter.allCases, id: \.self) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                        // Haptic feedback for accessibility
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filter accessibility features")
    }
}

struct FilterButton: View {
    let filter: AccessibilityFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(filter.emoji)
                    .font(.system(size: 18))
                    .accessibilityHidden(true)

                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(22)
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(isSelected ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel(filter.rawValue)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Filter map to show \(filter.rawValue.lowercased()) features")
    }
}

#Preview {
    FilterBar(selectedFilter: .constant(.all))
        .padding()
}
