//
//  LoadingIndicator.swift
//  LocAbility
//
//  Petros Dhespollari © 2025
//  Shared animated loader used across views
//

import SwiftUI

struct LoadingIndicator: View {
    var text: String? = nil
    var size: CGFloat = 64
    var textColor: Color? = nil

    @State private var rotation = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .green, .cyan, .blue]),
                            center: .center
                        ),
                        lineWidth: 6
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(rotation ? 360 : 0))
                    .animation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false), value: rotation)

                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: size * 0.55, height: size * 0.55)
                    .scaleEffect(pulse ? 1 : 0.85)
                    .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
            }
            .onAppear {
                rotation = true
                pulse = true
            }

            if let text {
                Text(text)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor ?? .secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text ?? "Loading")
    }
}

#Preview {
    LoadingIndicator(text: "Fetching accessible locations…")
}
